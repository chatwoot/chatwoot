# Chatwoot Customization

## Overview
This is a standard Chatwoot installation with an added voice note feature in the chat widget for customers. The installation is deployed on Fly.io.

## Infrastructure
- **App**: Deployed on Fly.io
- **Sidekiq**: Deployed on Fly.io
- **Redis**: Deployed on Fly.io
- **Tigris**: Deployed on Fly.io
- **Database**: External PostgreSQL installation (not on Fly.io)
  - Using existing PostgreSQL installation with pgvector support
  - Database name: "chatwoot"
  - Note: Not deployed on Fly.io due to pgvector support limitations

## Configuration

### Important Configuration Files
- `customconfig` folder contains Cacheable Docker image, post-deploy script and fly.toml
- `post-deploy` always ensure DB is migrated when we update version or deploy. Also reset license type to self hosted 
- `fly.toml` contains self-explanatory environment variables
- Storage options configuration is crucial:
  - Options: local, s3_compatible, or amazon s3
  - Note: Any storage apart from amazon s3 is considered s3_compatible
  - Refer to Chatwoot documentation for storage configuration changes

### Environment Secrets
The following secrets need to be configured (not in fly.toml):

| Secret | Description |
|--------|-------------|
| `DATABASE_URL` | Must include database name at the end |
| `REDIS_URL` | Using Upstash Redis in the same region as Fly app |
| `SECRET_KEY_BASE` | Secret key for Chatwoot (must be consistent across deployments) |
| `STORAGE_ACCESS_KEY_ID` | Provided when creating Tigris storage |
| `STORAGE_SECRET_ACCESS_KEY` | Provided when creating Tigris storage |

### Tigris Configuration
When running `fly tigris create`, you'll receive the following values to set in `fly.toml`:
- `STORAGE_BUCKET_NAME`
- `S3_ENDPOINT`
- `ACTIVE_STORAGE_CDN_HOST`
- `STORAGE_ENDPOINT`

You can view Tigris credentials using `fly tigris create`

### Deployment
To deploy on fly, just run `fly deploy -c customconfig/fly.toml`

## Regarding Post-deploy script
- Ensures that db:migrated whenever there is deployment
- Ensures that after that, installation target is self hosted to avoid issues with license change. We had issues with chatwoot resetting itself automatically to commercial license.

## Custom Widget Changes
- Voice recording feature has been added to the chat widget
- Contact SC for details about widget changes
- Note: These changes are temporary and will be removed once Chatwoot officially introduces voice recording for customers

