# Restoring from AWS Glacier Deep Archive

This guide covers how to restore your Umami database from a Glacier Deep Archive backup.

## Important: Restoration Timeline

Glacier Deep Archive retrievals take **12-48 hours**. Plan accordingly for disaster recovery scenarios.

## Step 1: List Available Backups

First, check your `.env` file for your S3 bucket name (`S3_BUCKET`) and prefix (`S3_PREFIX`), then list available backups:

```bash
aws s3 ls s3://your-bucket-name/umami-backups/
```

Identify the backup you want to restore. Filenames follow the pattern: `umami_backup_YYYYMMDD_HHMMSS.sql.gz`

## Step 2: Initiate Restoration

Request retrieval from Glacier Deep Archive:

```bash
aws s3api restore-object \
    --bucket your-bucket-name \
    --key umami-backups/umami_backup_YYYYMMDD_HHMMSS.sql.gz \
    --restore-request '{"Days":1,"GlacierJobParameters":{"Tier":"Bulk"}}'
```

**Tier options:**

- `Bulk` - 12-48 hours, lowest cost (~$0.0025/GB)
- `Standard` - 3-5 hours, higher cost (~$0.02/GB)

## Step 3: Check Restoration Status

Wait 12-48 hours, then check if the restore is complete:

```bash
aws s3api head-object \
    --bucket your-bucket-name \
    --key umami-backups/umami_backup_YYYYMMDD_HHMMSS.sql.gz
```

Look for `"Restore": "ongoing-request=\"false\""` in the output, which indicates the file is ready to download.

## Step 4: Download the Backup

Once restoration is complete:

```bash
aws s3 cp \
    s3://your-bucket-name/umami-backups/umami_backup_YYYYMMDD_HHMMSS.sql.gz \
    ./umami_backup_YYYYMMDD_HHMMSS.sql.gz
```

## Step 5: Decompress the Backup

```bash
gunzip umami_backup_YYYYMMDD_HHMMSS.sql.gz
```

This creates `umami_backup_YYYYMMDD_HHMMSS.sql`

## Step 6: Restore to Database

**Option A: Restore to existing database (overwrites data)**

```bash
# Stop the Umami application first to prevent conflicts
docker compose stop umami

# Restore the database
docker exec -i umami-db-1 psql -U umami umami < umami_backup_YYYYMMDD_HHMMSS.sql

# Restart the application
docker compose start umami
```

**Option B: Test restore in a separate container (recommended for testing)**

```bash
# Create a temporary PostgreSQL container
docker run -d --name postgres-restore \
    -e POSTGRES_DB=umami \
    -e POSTGRES_USER=umami \
    -e POSTGRES_PASSWORD=test123 \
    postgres:17-alpine

# Wait a few seconds for PostgreSQL to initialize
sleep 5

# Restore to the test container
docker exec -i postgres-restore psql -U umami umami < umami_backup_YYYYMMDD_HHMMSS.sql

# Verify the restore worked
docker exec postgres-restore psql -U umami umami -c "SELECT COUNT(*) FROM account;"

# Clean up when done
docker stop postgres-restore
docker rm postgres-restore
```

## Step 7: Verify Restoration

After restoring to your production database:

1. Access your Umami instance at `https://your-domain.com`
2. Log in and verify your analytics data is present
3. Check that the date range matches your expectations

## Notes

- The restored file is available in S3 Standard storage for the number of days specified (default: 1 day)
- After the temporary copy expires, the Glacier Deep Archive copy remains intact
- You can re-initiate restoration if needed
- Consider testing the restoration process periodically to ensure your backups are valid
