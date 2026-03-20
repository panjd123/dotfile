# Aggregate process stats for commands matching a keyword.
pstat() {
    if [ -z "$1" ]; then
        echo "Usage: pstat <keyword>"
        return 1
    fi

    keyword="$1"

    echo "Processes matching: $keyword"
    echo "-----------------------------------------------------------------------"
    printf "%-8s %-8s %-8s %-10s %s\n" "PID" "CPU%" "MEM%" "RSS(MB)" "CMD"

    ps ax -o pid,pcpu,pmem,rss,cmd | grep -F "$keyword" | grep -v grep | while read pid cpu mem rss cmd; do
        rss_mb=$(awk -v r="$rss" 'BEGIN{printf "%.1f", r/1024}')
        printf "%-8s %-8s %-8s %-10s %s\n" "$pid" "$cpu" "$mem" "$rss_mb" "$cmd"
    done

    cpu_sum=$(ps ax -o pcpu,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{print sum}')
    mem_sum=$(ps ax -o pmem,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{print sum}')
    rss_sum=$(ps ax -o rss,cmd | grep -F "$keyword" | grep -v grep | awk '{sum+=$1} END{printf "%.1f", sum/1024}')

    echo "-----------------------------------------------------------------------"
    echo "Total CPU%: $cpu_sum"
    echo "Total MEM%: $mem_sum"
    echo "Total RSS : $rss_sum MB"
}
