# Setup for Self-Hosting Umami Analytics

## Quick Start

1. Clone the repository:

```bash
   git clone https://github.com/yourusername/umami-analytics-setup
   cd umami-analytics-setup
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
