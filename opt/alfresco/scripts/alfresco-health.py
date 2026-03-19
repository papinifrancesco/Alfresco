#!/usr/bin/env python3
"""
alfresco-health — Alfresco stack health checker

Usage:
  alfresco-health           # coloured terminal report
  alfresco-health --json    # machine-readable JSON
  alfresco-health --watch   # refresh every 5 seconds (Ctrl-C to stop)
  alfresco-health --watch N # refresh every N seconds

Exit code: 0 = all services OK, 1 = one or more degraded/down.
"""

import base64
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

# ---------------------------------------------------------------------------
# Service catalogue
# ---------------------------------------------------------------------------

SERVICES = [
    dict(
        unit    = 'activemq.service',
        label   = 'ActiveMQ',
        url     = ('http://localhost:8161/api/jolokia/read/'
                   'org.apache.activemq:type=Broker,brokerName=localhost/'
                   'BrokerName,UptimeMillis,TotalConnectionsCount'),
        jolokia = True,
        headers = {
            'Authorization': 'Basic ' + base64.b64encode(b'admin:admin').decode(),
            'Origin': 'http://localhost:8161',
        },
    ),
    dict(
        unit    = 'alfresco-shared-file.service',
        label   = 'Shared File Store',
        url     = 'http://localhost:8099/ready',
        sfs     = True,   # expects body containing "Success"
    ),
    dict(
        unit    = 'alfresco-transform-core.service',
        label   = 'Transform Core AIO',
        url     = 'http://localhost:8090/actuator/health',
        actuator= True,
    ),
    dict(
        unit    = 'alfresco-transform-router.service',
        label   = 'Transform Router',
        url     = 'http://localhost:8095/actuator/health',
        actuator= True,
    ),
    dict(
        unit    = 'alfresco.service',
        label   = 'ACS Repository',
        url     = 'http://localhost:8080/alfresco/',
        actuator= False,
    ),
    dict(
        unit    = 'solr.service',
        label   = 'Alfresco Search (Solr)',
        url     = 'http://localhost:8983/solr/alfresco/admin/ping?wt=json',
        actuator= False,
        solr    = True,
        headers = {'X-Alfresco-Search-Secret': 'Tai22'},
    ),
]

HTTP_TIMEOUT = 5  # seconds per probe

# ---------------------------------------------------------------------------
# ANSI colours (suppressed when stdout is not a TTY)
# ---------------------------------------------------------------------------

def _use_colour():
    return sys.stdout.isatty()

def _c(code):
    return code if _use_colour() else ''

GREEN  = _c('\033[32m')
RED    = _c('\033[31m')
YELLOW = _c('\033[33m')
BOLD   = _c('\033[1m')
DIM    = _c('\033[2m')
RESET  = _c('\033[0m')

# ---------------------------------------------------------------------------
# systemd helpers
# ---------------------------------------------------------------------------

_SHOW_PROPS = 'ActiveState,SubState,MainPID,MemoryCurrent,ActiveEnterTimestamp'

def _systemd_props(unit):
    try:
        raw = subprocess.check_output(
            ['systemctl', 'show', unit, '--property=' + _SHOW_PROPS],
            text=True, stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return {}
    props = {}
    for line in raw.splitlines():
        k, _, v = line.partition('=')
        props[k.strip()] = v.strip()
    return props


def _fmt_uptime(ts):
    """'Mon 2026-03-16 20:15:00 CET' → '3d 8h' / '12m' / '—'"""
    if not ts or ts == 'n/a':
        return '—'
    try:
        parts = ts.split()
        dt = datetime.strptime(f'{parts[1]} {parts[2]}', '%Y-%m-%d %H:%M:%S')
        secs = max(0, int((datetime.now() - dt).total_seconds()))
        d, rem  = divmod(secs, 86400)
        h, rem  = divmod(rem,  3600)
        m       = rem // 60
        if d:   return f'{d}d {h}h'
        if h:   return f'{h}h {m}m'
        return  f'{m}m'
    except Exception:
        return '—'


def _fmt_mem(raw):
    """Bytes string → '1.2 GB' / '430 MB' / '—'"""
    if not raw or raw in ('', '[not set]', '18446744073709551615'):
        return '—'
    try:
        b = int(raw)
        if b >= 1 << 30: return f'{b / (1 << 30):.1f} GB'
        if b >= 1 << 20: return f'{b / (1 << 20):.0f} MB'
        return f'{b / 1024:.0f} KB'
    except ValueError:
        return '—'

# ---------------------------------------------------------------------------
# HTTP helper
# ---------------------------------------------------------------------------

def _http_check(url, actuator, solr=False, jolokia=False, sfs=False, headers=None):
    """
    Returns (ok: bool, detail: str).
    ok=None means no check configured.
    For actuator endpoints: parses JSON {'status': 'UP'|...}.
    For solr endpoints:     parses JSON {'status': 'OK'|...}.
    For jolokia endpoints:  parses Jolokia envelope {'status': 200, 'value': {...}}.
    For sfs endpoints:      expects HTTP 200 with body containing "Success".
    For plain endpoints:    any HTTP response is considered OK.
    """
    if url is None:
        return None, '—'
    try:
        req = urllib.request.Request(url, headers=headers or {})
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
            code = resp.status
            body = resp.read(4096).decode('utf-8', errors='replace')
            if actuator:
                try:
                    status = json.loads(body).get('status', '?')
                    return status == 'UP', status
                except Exception:
                    return True, f'HTTP {code}'
            if solr:
                try:
                    status = json.loads(body).get('status', '?')
                    return status == 'OK', status
                except Exception:
                    return True, f'HTTP {code}'
            if jolokia:
                try:
                    data   = json.loads(body)
                    j_ok   = data.get('status') == 200
                    value  = data.get('value', {})
                    conns  = value.get('TotalConnectionsCount', '?')
                    detail = f'OK ({conns} conn)'
                    return j_ok, detail if j_ok else f'Jolokia {data.get("status")}'
                except Exception:
                    return True, f'HTTP {code}'
            if sfs:
                ok = 'Success' in body
                return ok, 'OK' if ok else 'No Success'
            return True, f'HTTP {code}'

    except urllib.error.HTTPError as e:
        if actuator:
            # Actuator may return 503 with a JSON body when status != UP
            try:
                body = e.read(4096).decode('utf-8', errors='replace')
                status = json.loads(body).get('status', str(e.code))
                return False, status
            except Exception:
                return False, f'HTTP {e.code}'
        if sfs:
            return False, f'HTTP {e.code}'
        # For plain endpoints any HTTP response means the port is alive
        return True, f'HTTP {e.code}'

    except urllib.error.URLError as e:
        reason = str(e.reason).lower()
        if 'refused'      in reason: return False, 'Connection refused'
        if 'timed out'    in reason: return False, 'Timeout'
        if 'timeout'      in reason: return False, 'Timeout'
        return False, str(e.reason)[:28]

    except Exception as e:
        return False, str(e)[:28]

# ---------------------------------------------------------------------------
# Core check logic
# ---------------------------------------------------------------------------

def check_all():
    results = []
    for svc in SERVICES:
        props = _systemd_props(svc['unit'])

        active = props.get('ActiveState', 'unknown')
        sub    = props.get('SubState',    'unknown')
        pid    = props.get('MainPID', '—')
        if pid == '0': pid = '—'
        mem    = _fmt_mem(props.get('MemoryCurrent', ''))
        uptime = _fmt_uptime(props.get('ActiveEnterTimestamp', ''))

        systemd_ok = (active == 'active' and sub == 'running')
        http_ok, http_detail = _http_check(
            svc.get('url'), svc.get('actuator', False),
            solr=svc.get('solr', False), jolokia=svc.get('jolokia', False),
            sfs=svc.get('sfs', False), headers=svc.get('headers'),
        )
        overall_ok = systemd_ok and (http_ok is None or http_ok is True)

        results.append(dict(
            label      = svc['label'],
            unit       = svc['unit'],
            active     = active,
            sub        = sub,
            pid        = pid,
            memory     = mem,
            uptime     = uptime,
            systemd_ok = systemd_ok,
            http_ok    = http_ok,
            http_detail= http_detail,
            overall_ok = overall_ok,
        ))
    return results

# ---------------------------------------------------------------------------
# Terminal report
# ---------------------------------------------------------------------------

# Column visible widths
_W = dict(svc=26, sys=14, http=20, pid=7, mem=8, up=9)

def _col(text, width, colour, align='<'):
    """Return a coloured, padded cell. Padding is based on visible text width."""
    padded = f'{text:{align}{width}}'
    return f'{colour}{padded}{RESET}' if colour else padded


def _systemd_cell(ok, active, sub):
    if ok:
        return _col(f'● active',           _W['sys'], GREEN)
    if active == 'activating':
        return _col(f'◍ activating',        _W['sys'], YELLOW)
    if active == 'failed':
        return _col(f'● failed',            _W['sys'], RED)
    return     _col(f'● {active}/{sub}',    _W['sys'], RED)


def _http_cell(ok, detail):
    if ok is None:
        return _col('—',          _W['http'], DIM)
    if ok:
        return _col(f'✓ {detail}', _W['http'], GREEN)
    return     _col(f'✗ {detail}', _W['http'], RED)


def print_report(results):
    all_ok = all(r['overall_ok'] for r in results)
    now    = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    ruler  = '─' * 78

    print()
    print(f'{BOLD}Alfresco Stack Health  —  {now}{RESET}')
    print(ruler)

    hdr = (f'  {"Service":<{_W["svc"]}}  {"Systemd":<{_W["sys"]}}'
           f'  {"HTTP":<{_W["http"]}}  {"PID":>{_W["pid"]}}'
           f'  {"Memory":>{_W["mem"]}}  {"Uptime":>{_W["up"]}}')
    print(f'{DIM}{hdr}{RESET}')
    print(ruler)

    for r in results:
        label    = f'  {r["label"]:<{_W["svc"]}}'
        sys_cell = _systemd_cell(r['systemd_ok'], r['active'], r['sub'])
        htp_cell = _http_cell(r['http_ok'], r['http_detail'])
        pid_cell = f'{r["pid"]:>{_W["pid"]}}'
        mem_cell = f'{r["memory"]:>{_W["mem"]}}'
        up_cell  = f'{r["uptime"]:>{_W["up"]}}'
        print(f'{label}  {sys_cell}  {htp_cell}  {pid_cell}  {mem_cell}  {up_cell}')

    print(ruler)
    if all_ok:
        print(f'  {GREEN}{BOLD}All services operational{RESET}')
    else:
        down = ', '.join(r['label'] for r in results if not r['overall_ok'])
        print(f'  {RED}{BOLD}DEGRADED — issues with: {down}{RESET}')
    print()

    return 0 if all_ok else 1

# ---------------------------------------------------------------------------
# JSON report
# ---------------------------------------------------------------------------

def print_json(results):
    all_ok = all(r['overall_ok'] for r in results)
    out = dict(
        timestamp = datetime.now().isoformat(),
        overall   = 'ok' if all_ok else 'degraded',
        services  = [
            dict(
                label   = r['label'],
                unit    = r['unit'],
                systemd = f'{r["active"]}/{r["sub"]}',
                http    = r['http_detail'],
                pid     = r['pid'],
                memory  = r['memory'],
                uptime  = r['uptime'],
                ok      = r['overall_ok'],
            )
            for r in results
        ],
    )
    print(json.dumps(out, indent=2))
    return 0 if all_ok else 1

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def _parse_args():
    args   = sys.argv[1:]
    as_json = '--json'  in args
    watch   = '--watch' in args
    interval = 5
    if watch:
        idx = args.index('--watch')
        if idx + 1 < len(args):
            try:
                interval = int(args[idx + 1])
            except ValueError:
                pass
    return as_json, watch, interval


def main():
    as_json, watch, interval = _parse_args()

    if watch and not as_json:
        try:
            while True:
                # Move cursor to top of screen on subsequent iterations
                print('\033[2J\033[H', end='')
                rc = print_report(check_all())
                print(f'{DIM}  Refreshing every {interval}s — Ctrl-C to stop{RESET}')
                time.sleep(interval)
        except KeyboardInterrupt:
            print()
            sys.exit(0)

    results = check_all()
    if as_json:
        sys.exit(print_json(results))
    else:
        sys.exit(print_report(results))


if __name__ == '__main__':
    main()
