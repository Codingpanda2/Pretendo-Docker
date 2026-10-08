#!/bin/sh

set -eu

buckets="pn-cdn pn-boss super-mario-maker"

mc alias set minio "${MINIO_ENDPOINT:-http://minio:9000}" "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD"

ensure_buckets() {
    for bucket in $buckets; do
        if ! mc ls "minio/$bucket" >/dev/null 2>&1; then
            mc mb "minio/$bucket"
        fi

        mc anonymous set download "minio/$bucket"
    done
}

ensure_buckets

if [ "${1:-}" = "--once" ]; then
    exit 0
fi

while :; do
    sleep 60
    ensure_buckets
done
