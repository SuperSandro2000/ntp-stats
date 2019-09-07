#!/bin/bash
set -eou pipefail

while [[ $# -gt 0 ]]; do
    case "$1" in
    "-h" | "--help")
        echo "Usage: $0 [--debug]"
        exit 0
        ;;
    "-d" | "--debug")
        debug=true
        ;;
    esac
    shift
done

if ! bc --version >/dev/null 2>&1; then
  echo "You need bc to run this scirpt."
  echo "On Debian-based systems you can install it with: apt install bc"
  exit 1
fi

if ! ntpq --version >/dev/null 2>&1; then
  echo "You need ntpq to run this scirpt."
  echo "On Debian-based systems you can install it with: apt install ntp"
  exit 1
fi

stats=$(ntpq -c sysstats)

uptime=$(echo -e "$stats" | awk 'NR==1{print $2}')
received_packets=$(echo -e "$stats" | awk 'NR==3{print $3}')
bad_packets=$(echo -e "$stats" | awk 'NR==6{print $5}')
auth_failed=$(echo -e "$stats" | awk 'NR==7{print $3}')
declined=$(echo -e "$stats" | awk 'NR==8{print $2}')
restricted=$(echo -e "$stats" | awk 'NR==9{print $2}')
rate_limited=$(echo -e "$stats" | awk 'NR==10{print $3}')

if [[ ${debug:-} == true ]]; then
    echo received_packets "$received_packets"
    echo bad_packets "$bad_packets"
    echo auth_failed "$auth_failed"
    echo declined "$declined"
    echo restricted "$restricted"
    echo rate_limited "$rate_limited"
    echo
fi

sec_per_month=$(echo '60 * 60 * 24 * 30.436875' | bc)
sent_packets=$(echo "$received_packets - $bad_packets - $auth_failed - $declined - $restricted - $rate_limited" | bc)
received_per_sec=$(echo "$received_packets / $uptime" | bc)
received_per_month=$(echo "$received_per_sec * $sec_per_month" | bc)
received_per_month_gigabyte=$(echo "$received_per_month * 110 / (10 ^ 9)" | bc)
sent_per_sec=$(echo "$received_packets / $uptime" | bc)
sent_per_month=$(echo "$sent_per_sec * $sec_per_month" | bc)
sent_per_month_gigabyte=$(echo "$sent_per_month * 110 / (10 ^ 9)" | bc)

echo === received ===
echo packets received: "$received_packets"
echo packets received per second: "$received_per_sec"
echo packets received per month: "$received_per_month"
echo gigabytes received per month: "$received_per_month_gigabyte"
echo
echo === sent ===
echo packets sent: "$sent_packets"
echo packets sent per second: "$sent_per_sec"
echo packets sent per month: "$sent_per_month"
echo gigabytes sent per month: "$sent_per_month_gigabyte"
