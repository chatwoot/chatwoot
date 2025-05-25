
## Local Development Setup

This guide will help you set up Chatwoot for local development. Follow these steps to get your development environment running.

### Prerequisites

#### Docker 
If you're using Docker, you only need:

1. **Docker and Docker Compose**
   - Docker Desktop (for macOS/Windows) or Docker Engine (for Linux)
   - Docker Compose v2.x
   - Verify installation:
     ```bash
     docker --version
     docker compose version
     ```

2. **Git** (for version control)
   - Latest version of Git
   - Verify installation:
     ```bash
     git --version
     ```

Docker will handle all other dependencies (Ruby, Node.js, PostgreSQL, Redis, etc.) automatically.


### Setting Up the Development Environment

1. **Clone the Repository**
   ```bash
   git clone https://github.com/chatwoot/chatwoot.git
   cd chatwoot
   ```

2. **Configure Environment Variables**
   - Copy the example environment file:
     ```bash
     cp .env.example .env
     ```
   - Update the following essential variables in `.env`:
     ```
     POSTGRES_HOST=postgres
     POSTGRES_USERNAME=postgres
     POSTGRES_PASSWORD=your_secure_password
     POSTGRES_DATABASE=chatwoot
     RAILS_ENV=development
     SECRET_KEY_BASE=your_secret_key_base
     ```

3. **Start the Development Environment**
   - Using Docker (Recommended):
     ```bash
     # Build and start all services
     docker compose up -d
     
     # Prepare the database
     docker compose run --rm rails bundle exec rails db:chatwoot_prepare
     
     # Verify services are running
     docker compose ps
     ```
   - Manual Setup (Alternative):
     ```bash
     # Install dependencies
     bundle install
     yarn install
     
     # Setup database
     bundle exec rails db:chatwoot_prepare
     
     # Start services
     bundle exec rails s
     yarn dev
     ```

4. **Access the Application**
   - Web Interface: http://localhost:3000
   - API: http://localhost:3000/api
   - Default admin credentials:
     - Email: admin@chatwoot.com
     - Password: chatwoot

### Testing Core Functionality

1. **Run Test Suites**
   ```bash
   # Backend tests
   docker compose run --rm rails bundle exec rspec
   
   # Frontend tests
   docker compose run --rm rails yarn test
   ```

2. **Verify Basic Features**
   - Log in to the admin dashboard
   - Create a new inbox
   - Add a website widget
   - Test the chat widget on a test page
   - Send and receive test messages

### Troubleshooting Common Issues

1. **Database Connection Issues**
   - Verify PostgreSQL is running: `docker compose ps postgres`
   - Check environment variables in `.env`
   - Ensure database is prepared: `docker compose run --rm rails bundle exec rails db:chatwoot_prepare`

2. **Service Startup Issues**
   - Check logs: `docker compose logs -f [service_name]`
   - Common services: rails, sidekiq, postgres, redis
   - Restart services: `docker compose restart [service_name]`

3. **Frontend Development Issues**
   - Clear node modules: `rm -rf node_modules && yarn install`
   - Rebuild assets: `yarn build`
   - Check browser console for errors

4. **Backend Development Issues**
   - Clear temporary files: `bundle exec rails tmp:clear`
   - Restart Rails server: `docker compose restart rails`
   - Check Rails logs: `docker compose logs -f rails`

### Development Workflow

1. **Creating a New Feature**
   ```bash
   # Create a new branch
   git checkout -b feature/your-feature-name
   
   # Make your changes
   # Run tests
   docker compose run --rm rails bundle exec rspec
   
   # Commit changes
   git add .
   git commit -m "Add your feature"
   
   # Push to your fork
   git push origin feature/your-feature-name
   ```

2. **Keeping Your Fork Updated**
   ```bash
   # Add upstream remote
   git remote add upstream https://github.com/chatwoot/chatwoot.git
   
   # Fetch upstream changes
   git fetch upstream
   
   # Update your develop branch
   git checkout develop
   git merge upstream/develop
   ```

### Additional Resources

- [API Documentation](https://www.chatwoot.com/developers/api)
- [Frontend Development Guide](https://www.chatwoot.com/docs/contributing/frontend)
- [Backend Development Guide](https://www.chatwoot.com/docs/contributing/backend)
- [Testing Guide](https://www.chatwoot.com/docs/contributing/testing)
- [Code Style Guide](https://www.chatwoot.com/docs/contributing/code-style)

