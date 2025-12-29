# Scripts

## backup-umami.sh

Automated monthly backup of Umami PostgreSQL database to AWS Glacier Deep Archive.

### Prerequisites

- AWS CLI installed and configured with credentials
- IAM user with `s3:PutObject` permission for your S3 bucket
- Docker access (user must be in `docker` group)

### Configuration

All configuration is managed in the `.env` file in the project root:

**Required variables:**

- `S3_BUCKET` - Your AWS S3 bucket name
- `POSTGRES_DB` - Database name (reused from docker-compose)
- `POSTGRES_USER` - Database user (reused from docker-compose)

**Optional variables:**

- `S3_PREFIX` - S3 key prefix (default: `umami-backups`)
- `POSTGRES_CONTAINER` - Container name (default: `umami-db-1`)
- `BACKUP_RETENTION_DAYS` - Days to keep local backups (default: 7)

### Usage

**Test manually:**

```bash
./scripts/backup-umami.sh
```

**Check backup log:**

```bash
cat ~/backups/umami/backup.log
```

**Verify S3 upload:**

```bash
aws s3 ls s3://your-bucket-name/umami-backups/
```

### Automated Schedule

Add to crontab for monthly backups on the 1st at 2 AM:

```bash
crontab -e
```

Add this line:

```
0 2 1 * * ~/selfhost-umami-analytics/scripts/backup-umami.sh
```

Note: adjust the path to wherever you've placed the script.

### What It Does

1. Reads configuration from `.env` file
2. Creates compressed PostgreSQL dump using `pg_dump` via Docker exec
3. Validates backup file is not empty
4. Uploads to S3 with `DEEP_ARCHIVE` storage class
5. Cleans up local backups older than retention period
6. Logs all operations

### Storage Costs

Glacier Deep Archive pricing is approximately $0.00099/GB/month. For a typical Umami database:

- 12 KB backup: <$0.01/year
- 100 MB backup: ~$1.20/year

### Notes

- Glacier Deep Archive has 12-48 hour retrieval time
- 180-day minimum storage duration applies
- Local backups are kept for 7 days by default to save disk space
- See [restoration-guide.md](../docs/restoration-guide.md) for instructions on restoring from a backup
