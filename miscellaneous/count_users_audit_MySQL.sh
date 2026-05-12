#!/usr/bin/env bash
# Method A: count distinct Alfresco-access audit users via SQL (MySQL,
# Alfresco 7.x schema).
#
# In Alfresco 4.x+, alf_prop_value stores only the persisted-type and a
# long_value pointer; the actual interned string lives in
# alf_prop_string_value.string_value, reached via long_value -> id.
#
# Requires the MySQL client. On Fedora:  sudo dnf install mariadb
#
# Usage:
#   DB_HOST=10.240.6.70 DB_PORT=3306 \
#   DB_USER=alfresco MYSQL_PWD='secret' \
#   DB_NAME=alfresco7_prod \
#       ./count_users_db.sh [output_dir]
#
# MYSQL_PWD is the standard env var the mysql client reads \Uffffffff it avoids
# exposing the password via `ps`. Do NOT pass the password as a CLI arg.
#
# Outputs (in $output_dir, defaults to script dir):
#   users_db.txt           \Uffffffff sorted distinct usernames (lowercased)
#   users_db_by_month.txt  \Uffffffff YYYY-MM, distinct active users that month
#   stdout                 \Uffffffff total count and audit time-span

set -euo pipefail

out_dir="${1:-$(dirname "$(readlink -f "$0")")}"
mkdir -p "$out_dir"

: "${DB_HOST:?DB_HOST not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${MYSQL_PWD:?MYSQL_PWD not set (export the password into MYSQL_PWD)}"
DB_PORT="${DB_PORT:-3306}"

MYSQL=(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -D "$DB_NAME" -N -B)

# Restrict to entries belonging to the alfresco-access audit application.
# alf_audit_app.app_name_id -> alf_prop_value.id -> alf_prop_string_value.
audit_app_filter="
  a.app_name_id IN (
    SELECT pv_app.id
    FROM   alf_prop_value        pv_app
    JOIN   alf_prop_string_value psv_app ON psv_app.id = pv_app.long_value
    WHERE  psv_app.string_value = 'alfresco-access'
  )
"

# Reusable join chain that turns audit_user_id into the username text.
user_joins="
  JOIN alf_prop_value        pv  ON pv.id  = e.audit_user_id
  JOIN alf_prop_string_value psv ON psv.id = pv.long_value
"

echo "==> Audit applications captured (sanity check)"
"${MYSQL[@]}" -e "
  SELECT psv.string_value AS app_name, COUNT(e.id) AS entries
  FROM   alf_audit_app          a
  JOIN   alf_prop_value         pv  ON pv.id  = a.app_name_id
  JOIN   alf_prop_string_value  psv ON psv.id = pv.long_value
  LEFT   JOIN alf_audit_entry   e   ON e.audit_app_id = a.id
  GROUP  BY psv.string_value
  ORDER  BY entries DESC;
"

echo "==> Audit time-span and entry count (alfresco-access)"
"${MYSQL[@]}" -e "
  SELECT FROM_UNIXTIME(MIN(audit_time)/1000) AS audit_starts_at,
         FROM_UNIXTIME(MAX(audit_time)/1000) AS audit_ends_at,
         COUNT(*)                            AS total_audit_entries
  FROM   alf_audit_entry e
  JOIN   alf_audit_app   a ON a.id = e.audit_app_id
  WHERE  $audit_app_filter;
"

echo "==> Distinct user count (lifetime, alfresco-access)"
"${MYSQL[@]}" -e "
  SELECT COUNT(DISTINCT LOWER(psv.string_value))
  FROM   alf_audit_entry  e
  JOIN   alf_audit_app    a ON a.id = e.audit_app_id
  $user_joins
  WHERE  $audit_app_filter
     AND psv.string_value IS NOT NULL
     AND psv.string_value <> 'System';
"

echo "==> Writing $out_dir/users_db.txt"
"${MYSQL[@]}" -e "
  SELECT DISTINCT LOWER(psv.string_value)
  FROM   alf_audit_entry  e
  JOIN   alf_audit_app    a ON a.id = e.audit_app_id
  $user_joins
  WHERE  $audit_app_filter
     AND psv.string_value IS NOT NULL
     AND psv.string_value <> 'System'
  ORDER  BY 1;
" > "$out_dir/users_db.txt"

echo "==> Writing $out_dir/users_db_by_month.txt"
"${MYSQL[@]}" -e "
  SELECT DATE_FORMAT(FROM_UNIXTIME(audit_time/1000), '%Y-%m') AS month,
         COUNT(DISTINCT LOWER(psv.string_value))              AS active_users
  FROM   alf_audit_entry  e
  JOIN   alf_audit_app    a ON a.id = e.audit_app_id
  $user_joins
  WHERE  $audit_app_filter
     AND psv.string_value <> 'System'
  GROUP  BY 1
  ORDER  BY 1;
" > "$out_dir/users_db_by_month.txt"

wc -l "$out_dir/users_db.txt" "$out_dir/users_db_by_month.txt"
