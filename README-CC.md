# ChatsCommerce Branded Chatwoot

This repository contains a customized version of Chatwoot with ChatsCommerce branding. It provides a complete customer communications platform with a branded interface and customized configuration.

## Key Components

- **Branding Assets**: Custom logos and icons in `public/brand-assets/chatscommerce/`
- **Custom Configuration**: Branded installation settings in `config/installation_config.yml`
- **Docker Setup**: Containerized deployment with `Dockerfile.custom` and `docker-compose.custom.yaml`
- **Taskfile**: Simplified command management in `Taskfile.yml`
- **Icon Generation**: Automated icon generation with `generate_icons.sh`

## Directory Structure

```
/
├── public/
│   ├── brand-assets/              # Branding assets
│   │   └── chatscommerce/         # ChatsCommerce branding files
│   │       ├── logo.png           # Primary logo
│   │       ├── logo_dark.png      # Logo for dark mode
│   │       └── logo_thumbnail.png # Logo thumbnail (512x512)
│   ├── favicon-*.png              # Various favicon sizes
│   ├── apple-icon-*.png           # Apple device icons
│   ├── android-icon-*.png         # Android device icons
│   └── ms-icon-*.png              # Microsoft device icons
├── config/
│   └── installation_config.yml    # Branding configuration
├── Dockerfile.custom              # Custom Docker build
├── docker-compose.custom.yaml     # Docker Compose configuration
├── Taskfile.yml                   # Task runner configuration
├── generate_icons.sh              # Script to generate all icon variations
└── .env.branded                   # Environment variables template
```

## Prerequisites

1. [Docker](https://www.docker.com/): For containerized deployment
2. [Docker Compose](https://docs.docker.com/compose/): For multi-container application orchestration
3. [Taskfile](https://taskfile.dev/): For simplified command management
4. [ImageMagick](https://imagemagick.org/): For icon generation (`brew install imagemagick` on macOS)

## Setup Process

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/chatscommerce-chatwoot.git
cd chatscommerce-chatwoot
```

### 2. Prepare Your Branding Assets

Place your branding assets in the appropriate directory:

```bash
mkdir -p public/brand-assets/chatscommerce
```

At minimum, add your primary logo:

```bash
cp /path/to/your/logo.png public/brand-assets/chatscommerce/logo.png
```

The system can generate additional required files automatically.

### 3. Initialize the Environment

Run the `prepare-env` task to create your `.env` file from the template:

```bash
task prepare-env
```

Edit the `.env` file to set your specific configuration values.

### 4. Generate All Branding Assets

Run the `verify-all-branding` task to check and generate all necessary branding assets:

```bash
task verify-all-branding
```

This will:
- Verify the existence of required branding directories
- Check for the primary logo.png
- Create logo_dark.png and logo_thumbnail.png if they don't exist
- Generate all icon variations for different platforms (favicons, Apple, Android, Microsoft)
- Create the browserconfig.xml file for Microsoft browsers

### 5. Build and Start the Application

To build the Docker image and start all services:

```bash
task run-all
```

This comprehensive task:
- Creates necessary directories
- Prepares environment variables
- Verifies and generates branding assets
- Builds the Docker image
- Starts all services
- Prepares the database

### 6. Access the Application

Once everything is running, access the application at:

```
http://localhost:3000
```

Or use the convenient task:

```bash
task open-app
```

## Available Tasks

The Taskfile provides several useful commands:

| Task | Description |
|------|-------------|
| `task docker-build` | Build the ChatsCommerce-branded Chatwoot Docker image |
| `task docker-up` | Start all Chatwoot services in detached mode |
| `task docker-down` | Stop all Chatwoot services |
| `task docker-logs` | Show logs from all services (or specify a service) |
| `task docker-rebuild` | Rebuild and restart all services |
| `task setup-dirs` | Create necessary directories for data persistence |
| `task prepare-env` | Create .env file from template if it doesn't exist |
| `task verify-branding` | Verify that basic branding assets exist |
| `task verify-all-branding` | Verify and generate all branding assets |
| `task generate-icons` | Generate all icon variations from logo.png |
| `task rails-console` | Access the Rails console inside the container |
| `task sidekiq-status` | Check Sidekiq status inside the container |
| `task rails-logs` | Show Rails logs |
| `task db-prepare` | Run database setup and migrations |
| `task db-seed` | Load seed data into the database |
| `task run-all` | Complete setup and start the application |
| `task open-app` | Open the application in the default browser |

## Branding Configuration

The branding configuration is defined in `config/installation_config.yml`. Key branding settings include:

```yaml
- name: INSTALLATION_NAME
  value: 'ChatsCommerce'
- name: LOGO_THUMBNAIL
  value: '/brand-assets/chatscommerce/logo_thumbnail.png'
- name: LOGO
  value: '/brand-assets/chatscommerce/logo.png'
- name: LOGO_DARK
  value: '/brand-assets/chatscommerce/logo_dark.png'
- name: BRAND_URL
  value: 'https://www.chatscommerce.com'
- name: WIDGET_BRAND_URL
  value: 'https://www.chatscommerce.com'
- name: BRAND_NAME
  value: 'ChatsCommerce'
```

## Icon Generation

The `generate_icons.sh` script automatically creates all necessary icon variations from your primary logo. The script uses ImageMagick to resize your logo to the various required sizes for different platforms:

- Favicons (16x16, 32x32, 96x96, 512x512)
- Apple Touch icons (various sizes)
- Android icons (various sizes)
- Microsoft tile icons (various sizes)


## Troubleshooting

### Icon Generation Issues

If you encounter issues with icon generation:
- Ensure ImageMagick is installed: `brew install imagemagick` (macOS) or `apt-get install imagemagick` (Ubuntu)
- Verify your source logo is a valid PNG file
- Check file permissions on the script: `chmod +x generate_icons.sh`
- If you see warnings about deprecated commands, you can safely ignore them—the script handles both older and newer versions of ImageMagick

### Docker Issues

If you encounter issues with Docker:
- Check if Docker is running: `docker info`
- Verify port 3000 is not in use by another application
- Check Docker logs: `task docker-logs`

### Database Issues

If you encounter database issues:
- Check database logs: `task docker-logs postgres`
- Run migrations manually: `task db-prepare`

## CI/CD Integration

To integrate with GitHub Actions or other CI/CD pipelines, you can use the Taskfile commands in your workflows. For example:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Taskfile
        uses: arduino/setup-task@v1
      - name: Build Docker image
        run: task docker-build
``` 