#!/bin/sh

set -eu

buckets="pn-cdn pn-boss super-mario-maker"

mc alias set minio "${MINIO_ENDPOINT:-http://minio:9000}" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

wait_for_minio() {
    attempts=0
    until mc ls minio >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 30 ]; then
            echo "MinIO did not become ready after 60 seconds." >&2
            return 1
        fi

        echo "Waiting for MinIO to become ready... ($attempts/30)" >&2
        sleep 2
    done
}

ensure_buckets() {
    for bucket in $buckets; do
        if ! mc ls "minio/$bucket" >/dev/null 2>&1; then
            mc mb "minio/$bucket"
        fi

        mc anonymous set download "minio/$bucket"
    done
}

wait_for_minio
ensure_buckets

if [ "${1:-}" = "--once" ]; then
    exit 0
fi

while :; do
    sleep 60
    ensure_buckets
done
