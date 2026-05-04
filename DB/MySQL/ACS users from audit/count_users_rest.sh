#!/usr/bin/env bash
# Method B: count distinct Alfresco-access audit users via the REST API.
#
# Usage:
#   ALF_BASE_URL=https://alfresco.example ALF_USER=admin ALF_PASS=secret \
#       ./count_users_rest.sh [output_dir]
#
# Outputs (in $output_dir, defaults to script dir):
#   users_rest.txt            — sorted distinct usernames (lowercased)
#   users_rest_by_month.txt   — YYYY-MM, distinct active users that month
#   entries_rest.tsv          — raw paginated dump (id, time_ms, user) for audit
#   stdout                    — total count and time-span

set -euo pipefail

out_dir="${1:-$(dirname "$(readlink -f "$0")")}"
mkdir -p "$out_dir"

: "${ALF_BASE_URL:?ALF_BASE_URL not set}"
: "${ALF_USER:?ALF_USER not set}"
: "${ALF_PASS:?ALF_PASS not set}"

raw="$out_dir/entries_rest.tsv"
: > "$raw"

from_id=0
limit=1000
total=0

echo "==> Paginating $ALF_BASE_URL/alfresco/s/api/audit/query/alfresco-access"
while :; do
    page=$(curl -fsSu "$ALF_USER:$ALF_PASS" \
        --get \
        --data-urlencode "verbose=false" \
        --data-urlencode "limit=$limit" \
        --data-urlencode "forward=true" \
        --data-urlencode "fromId=$from_id" \
        "$ALF_BASE_URL/alfresco/s/api/audit/query/alfresco-access")

    n=$(jq '.entries | length' <<<"$page")
    [ "$n" -eq 0 ] && break

    jq -r '.entries[] | [.id, .time, (.user // "")] | @tsv' <<<"$page" >> "$raw"

    from_id=$(jq '(.entries[-1].id) + 1' <<<"$page")
    total=$((total + n))
    printf "  fetched %d (running total %d, next fromId=%d)\n" "$n" "$total" "$from_id"

    [ "$n" -lt "$limit" ] && break
done

echo "==> $total raw audit entries written to $raw"

echo "==> Writing $out_dir/users_rest.txt"
awk -F'\t' '{
    u = $3
    if (u == "" || u == "System") next
    print tolower(u)
}' "$raw" | sort -u > "$out_dir/users_rest.txt"

echo "==> Writing $out_dir/users_rest_by_month.txt"
awk -F'\t' '{
    u = $3
    if (u == "" || u == "System") next
    # $2 is epoch milliseconds
    secs = int($2 / 1000)
    month = strftime("%Y-%m", secs, 1)
    key = month "\t" tolower(u)
    if (!(key in seen)) {
        seen[key] = 1
        count[month]++
    }
}
END {
    for (m in count) print m "\t" count[m]
}' "$raw" | sort > "$out_dir/users_rest_by_month.txt"

echo "==> Distinct user count (lifetime, alfresco-access via REST)"
wc -l < "$out_dir/users_rest.txt"

if [ -s "$raw" ]; then
    awk -F'\t' '
        NR == 1 { min = $2; max = $2 }
        { if ($2 < min) min = $2; if ($2 > max) max = $2 }
        END {
            printf "audit_starts_at\t%s\n", strftime("%Y-%m-%d %H:%M:%S", int(min/1000), 1)
            printf "audit_ends_at  \t%s\n", strftime("%Y-%m-%d %H:%M:%S", int(max/1000), 1)
            printf "total_entries  \t%d\n", NR
        }
    ' "$raw"
fi
