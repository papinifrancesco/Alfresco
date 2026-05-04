#!/usr/bin/env bash
# Run both methods and diff their distinct-user lists.
#
# Expects PG* env vars (for count_users_db.sh) and ALF_* env vars
# (for count_users_rest.sh) to be set; see those scripts.

set -euo pipefail

here="$(dirname "$(readlink -f "$0")")"

"$here/count_users_db.sh"   "$here"
"$here/count_users_rest.sh" "$here"

echo
echo "==> diff users_db.txt vs users_rest.txt"
if diff -u "$here/users_db.txt" "$here/users_rest.txt"; then
    echo "MATCH: both methods agree on the distinct-user set."
else
    echo "MISMATCH: investigate before reporting figures to procurement."
    echo "  - lines starting with '-' are in DB but missing from REST"
    echo "  - lines starting with '+' are in REST but missing from DB"
fi

echo
echo "==> per-month side-by-side"
join -t $'\t' -a1 -a2 -e '-' -o '0,1.2,2.2' \
    "$here/users_db_by_month.txt" "$here/users_rest_by_month.txt" \
    | column -t -s $'\t' -N month,db,rest
