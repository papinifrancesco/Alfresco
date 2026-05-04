#!/usr/bin/env bash
# Method A: count distinct Alfresco-access audit users via SQL.
#
# Usage:
#   PGHOST=db PGPORT=5432 PGUSER=alfresco PGPASSWORD=secret PGDATABASE=alfresco \
#       ./count_users_db.sh [output_dir]
#
# Outputs (in $output_dir, defaults to script dir):
#   users_db.txt           — sorted distinct usernames (lowercased)
#   users_db_by_month.txt  — YYYY-MM, distinct active users that month
#   stdout                 — total count and audit time-span

set -euo pipefail

out_dir="${1:-$(dirname "$(readlink -f "$0")")}"
mkdir -p "$out_dir"

: "${PGHOST:?PGHOST not set}"
: "${PGUSER:?PGUSER not set}"
: "${PGDATABASE:?PGDATABASE not set}"

PSQL=(psql -X -A -t -v ON_ERROR_STOP=1)

audit_app_filter="
  a.app_name_id IN (
    SELECT id FROM alf_prop_value WHERE string_value = 'alfresco-access'
  )
"

echo "==> Audit time-span and entry count"
"${PSQL[@]}" -F $'\t' -c "
  SELECT to_timestamp(MIN(audit_time)/1000)::timestamp(0) AS audit_starts_at,
         to_timestamp(MAX(audit_time)/1000)::timestamp(0) AS audit_ends_at,
         COUNT(*) AS total_audit_entries
  FROM   alf_audit_entry e
  JOIN   alf_audit_application a ON a.id = e.audit_app_id
  WHERE  $audit_app_filter;
"

echo "==> Distinct user count (lifetime, alfresco-access)"
"${PSQL[@]}" -c "
  SELECT COUNT(DISTINCT lower(pv.string_value))
  FROM   alf_audit_entry  e
  JOIN   alf_audit_application a ON a.id = e.audit_app_id
  JOIN   alf_prop_value   pv ON pv.id = e.audit_user_id
  WHERE  $audit_app_filter
     AND pv.string_value IS NOT NULL
     AND pv.string_value <> 'System';
"

echo "==> Writing $out_dir/users_db.txt"
"${PSQL[@]}" -c "
  SELECT DISTINCT lower(pv.string_value)
  FROM   alf_audit_entry  e
  JOIN   alf_audit_application a ON a.id = e.audit_app_id
  JOIN   alf_prop_value   pv ON pv.id = e.audit_user_id
  WHERE  $audit_app_filter
     AND pv.string_value IS NOT NULL
     AND pv.string_value <> 'System'
  ORDER  BY 1;
" > "$out_dir/users_db.txt"

echo "==> Writing $out_dir/users_db_by_month.txt"
"${PSQL[@]}" -F $'\t' -c "
  SELECT to_char(to_timestamp(audit_time/1000), 'YYYY-MM') AS month,
         COUNT(DISTINCT lower(pv.string_value))           AS active_users
  FROM   alf_audit_entry  e
  JOIN   alf_audit_application a ON a.id = e.audit_app_id
  JOIN   alf_prop_value   pv ON pv.id = e.audit_user_id
  WHERE  $audit_app_filter
     AND pv.string_value <> 'System'
  GROUP  BY 1
  ORDER  BY 1;
" > "$out_dir/users_db_by_month.txt"

wc -l "$out_dir/users_db.txt" "$out_dir/users_db_by_month.txt"
