# Setup for Self-Hosting Umami Analytics

A ready-to-deploy configuration for self-hosting [Umami](https://umami.is/), a privacy-focused, open-source web analytics platform. This setup includes automatic HTTPS via Caddy and optional automated backups to AWS Glacier Deep Archive.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- A domain name with DNS access (for VPS deployment)
- (Optional) [AWS CLI](https://aws.amazon.com/cli/) configured with credentials for automated backups

## Quick Start on a VPS

1. Clone the repository:

```bash
   git clone https://github.com/photon-collider/selfhost-umami-analytics
   cd selfhost-umami-analytics
```

2. Configure your environment:

```bash
   cp .env.example .env
   nano .env  # Update all values
```

Required changes:

- `DOMAIN`: Your domain name
- `POSTGRES_PASSWORD`: Strong password for database
- `APP_SECRET`: Generate with `openssl rand -base64 32`

3. Point your domain's DNS A record to your server's IP

4. Start the stack:

```bash
   docker compose up -d
```

5. Access Umami at `https://your-domain.com`

## Local Development & Testing

To test the setup locally before deploying to your VPS:

1. Create a `.env` file (same as production setup):

```bash
cp .env.example .env
# Update POSTGRES_PASSWORD and APP_SECRET
# DOMAIN can be left as-is (ignored in local mode)
```

2. Run with the local override:

```bash
docker compose -f docker-compose.yml -f docker-compose.local.yml up
```

3. Access Umami at `http://localhost:3000`

**What's different in local mode:**

- Umami is exposed directly on port 3000 (no Caddy/HTTPS)
- Caddy doesn't run (skipped via profile)
- Same database and application behavior as production

**Default login:**

- Username: `admin`
- Password: `umami`

To stop: `Ctrl+C` or `docker compose -f docker-compose.yml -f docker-compose.local.yml down`
