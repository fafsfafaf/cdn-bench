#!/usr/bin/env bash
# cdn-bench — benchmark global CDNs from your machine.
# Cloudflare vs Bunny vs Fastly vs jsDelivr vs AWS CloudFront vs Akamai
# vs Azure Front Door vs Google Cloud CDN.
#
#   bash cdn-bench.sh
#
set -u
VERSION="1.0.0"

if [ -t 1 ]; then
    B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
    G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; M=$'\033[35m'
else B=""; D=""; R=""; G=""; Y=""; C=""; M=""; fi

command -v curl >/dev/null || { echo "curl required"; exit 1; }

# CDN test targets: small static asset known to be cached on each CDN's edge.
# Format: name|url
TARGETS=(
    "Cloudflare|https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js"
    "jsDelivr|https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"
    "Bunny|https://bunny.net/img/logos/bunny-logo-light.png"
    "Fastly|https://fastly.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"
    "Akamai|https://www.akamai.com/site/dam/svg/akamai-logo-rgb.svg"
    "CloudFront|https://d1.awsstatic.com/logos/aws_logo_smile_1200x630.png"
    "GoogleCDN|https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js"
    "MS Azure|https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.7.1.min.js"
    "UNPKG|https://unpkg.com/jquery@3.7.1/dist/jquery.min.js"
)

ROUNDS=3

printf '\n%scdn-bench v%s%s · %d CDNs · %d rounds each\n\n' "$B" "$VERSION" "$R" "${#TARGETS[@]}" "$ROUNDS"

printf '  %s%-12s  %-8s  %-9s  %-8s  %-12s%s\n' "$B" "CDN" "DNS" "CONNECT" "TLS" "TOTAL (avg)" "$R"
printf '  %s' "$D"
printf -- '─%.0s' {1..58}
printf '%s\n' "$R"

declare -A RESULTS

for entry in "${TARGETS[@]}"; do
    name="${entry%%|*}"; url="${entry##*|}"

    SUM_DNS=0; SUM_CONN=0; SUM_TLS=0; SUM_TOT=0; OK=0
    for i in $(seq 1 $ROUNDS); do
        OUT=$(curl -fsS -o /dev/null --max-time 8 \
              -w '%{time_namelookup} %{time_connect} %{time_appconnect} %{time_total}\n' \
              "$url" 2>/dev/null)
        if [ -n "$OUT" ]; then
            d=$(echo "$OUT" | awk '{print $1}')
            c=$(echo "$OUT" | awk '{print $2}')
            t=$(echo "$OUT" | awk '{print $3}')
            T=$(echo "$OUT" | awk '{print $4}')
            SUM_DNS=$(awk -v a="$SUM_DNS"  -v b="$d" 'BEGIN{printf "%.6f", a+b}')
            SUM_CONN=$(awk -v a="$SUM_CONN" -v b="$c" 'BEGIN{printf "%.6f", a+b}')
            SUM_TLS=$(awk -v a="$SUM_TLS"  -v b="$t" 'BEGIN{printf "%.6f", a+b}')
            SUM_TOT=$(awk -v a="$SUM_TOT"  -v b="$T" 'BEGIN{printf "%.6f", a+b}')
            OK=$((OK+1))
        fi
    done

    if [ "$OK" -gt 0 ]; then
        DNS_MS=$(awk -v s="$SUM_DNS"  -v n="$OK" 'BEGIN{printf "%.0f", (s/n)*1000}')
        CONN_MS=$(awk -v s="$SUM_CONN" -v n="$OK" 'BEGIN{printf "%.0f", (s/n)*1000}')
        TLS_MS=$(awk -v s="$SUM_TLS"  -v n="$OK" 'BEGIN{printf "%.0f", (s/n)*1000}')
        TOT_MS=$(awk -v s="$SUM_TOT"  -v n="$OK" 'BEGIN{printf "%.0f", (s/n)*1000}')
        # Color total
        if [ "$TOT_MS" -lt 50 ];   then col="$G"
        elif [ "$TOT_MS" -lt 150 ]; then col="$C"
        elif [ "$TOT_MS" -lt 400 ]; then col="$Y"
        else col="$M"; fi
        printf '  %s%-12s%s  %-8s  %-9s  %-8s  %s%-12s%s\n' \
            "$C" "$name" "$R" "${DNS_MS}ms" "${CONN_MS}ms" "${TLS_MS}ms" "$col" "${TOT_MS}ms" "$R"
        RESULTS["$name"]="$TOT_MS"
    else
        printf '  %s%-12s%s  %s%-50s%s\n' "$C" "$name" "$R" "$Y" "failed" "$R"
    fi
done

# Winner
echo
WINNER=""; WINNER_MS=99999
for n in "${!RESULTS[@]}"; do
    ms="${RESULTS[$n]}"
    if [ "$ms" -lt "$WINNER_MS" ]; then WINNER="$n"; WINNER_MS="$ms"; fi
done
[ -n "$WINNER" ] && printf '  %s🏆 fastest CDN from your location:%s %s%s%s (%sms total)\n\n' \
    "$B" "$R" "$G" "$WINNER" "$R" "$WINNER_MS"
