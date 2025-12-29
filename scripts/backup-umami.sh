#!/bin/bash

# Umami PostgreSQL Backup Script for AWS Glacier Deep Archive

set -e  # Exit on any error

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source environment variables from .env file in parent directory
ENV_FILE="$SCRIPT_DIR/../.env"
if [ -f "$ENV_FILE" ]; then
    # Export variables from .env, ignoring comments and empty lines
    set -a
    source <(grep -v '^#' "$ENV_FILE" | grep -v '^$')
    set +a
else
    echo "ERROR: .env file not found at $ENV_FILE" >&2
    exit 1
fi

# Determine backup directory and log file based on user
if [ "$(whoami)" = "root" ]; then
    BACKUP_DIR="/var/backups/umami"
    LOG_FILE="/var/log/umami-backup.log"
else
    BACKUP_DIR="$HOME/backups/umami"
    LOG_FILE="$HOME/backups/umami/backup.log"
fi

# Configuration from .env
S3_BUCKET="${S3_BUCKET:?S3_BUCKET not set in .env}"
S3_PREFIX="${S3_PREFIX:-umami-backups}"
DB_NAME="${POSTGRES_DB:?POSTGRES_DB not set in .env}"
DB_USER="${POSTGRES_USER:?POSTGRES_USER not set in .env}"
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-selfhost-umami-analytics-db-1}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Logging
exec 1>> "$LOG_FILE"
exec 2>&1

echo "========================================="
echo "Backup started at $(date)"
echo "========================================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/umami_backup_$TIMESTAMP.sql.gz"

# Create database backup using docker exec
echo "Creating database dump from container $POSTGRES_CONTAINER..."
docker exec "$POSTGRES_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Verify backup file
if [ ! -s "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file is empty or doesn't exist!" >&2
    exit 1
fi

FILESIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null)
echo "Backup file created: $BACKUP_FILE (Size: $FILESIZE bytes)"

if [ "$FILESIZE" -lt 1024 ]; then
    echo "ERROR: Backup file suspiciously small ($FILESIZE bytes)" >&2
    exit 1
fi

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/$S3_PREFIX/" \
    --storage-class DEEP_ARCHIVE \
    --only-show-errors

echo "SUCCESS: Backup uploaded to s3://$S3_BUCKET/$S3_PREFIX/umami_backup_$TIMESTAMP.sql.gz"

# Clean up old local backups
echo "Cleaning up local backups older than $RETENTION_DAYS days..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "umami_backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
echo "Deleted $DELETED_COUNT old local backup(s)"

echo "Backup process completed successfully at $(date)"
echo ""