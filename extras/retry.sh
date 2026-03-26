#!/bin/sh
# Retry a command with linear backoff
# Usage: retry <max_attempts> <command...>
# Example: retry 3 curl -sSLf -o /tmp/file https://example.com/file

MAX=$1
shift

for ATTEMPT in $(seq 1 "$MAX"); do
    if "$@"; then
        exit 0
    fi
    if [ "$ATTEMPT" -lt "$MAX" ]; then
        SLEEP_TIME=$((5 * ATTEMPT))
        echo "Attempt $ATTEMPT/$MAX failed, retrying in ${SLEEP_TIME}s..."
        sleep "$SLEEP_TIME"
    fi
done

echo "Failed after $MAX attempts: $*"
exit 1
