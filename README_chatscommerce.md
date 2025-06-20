
# ChatsCommerce - Chatwoot Web UI/Server

## Dependencies
- Docker
- Node.js (v20+)
- Ruby (v3.4.4)
- PNPM

## Development Environment Setup
### 1. Install Dependencies
*NOTE:* Install dependencies based on your OS.

- [Mac OS](https://developers.chatwoot.com/contributing-guide/environment-setup/mac-os)
- [Ubuntu](https://developers.chatwoot.com/contributing-guide/environment-setup/ubuntu)
- [Windows](https://developers.chatwoot.com/contributing-guide/environment-setup/windows)

### 2. Install Packages
This will install all dependencies (Ruby gems and Node packages)
```
make burn 
```

### 3. Setup Environment Variables
Make a copy of the example environment file
```
cp .env.example .env
```
Download the recommended .env file 
[TBD]

## Docker Setup
### 1. Update Environment Variables
Update Redis and Postgres passwords to match in .env and docker-compose.yaml
- `REDIS_PASSWORD`
- `POSTGRES_PASSWORD`

### 2. Build the images
#### 2.a. Build the base image first
```
docker compose build base
```
#### 2.b. Build the whole stack
```
docker compose build
```

### 3. Prepare the Database
After re-building or making changes to the database schema you need to prepare or reset the database.
#### 3.a. Prepare the Database
```
docker compose run --rm rails bundle exec rails db:chatwoot_prepare
```
#### 3.b. Reset the Database
```
docker compose run --rm rails bundle exec rails db:reset
```

### 4. Run the App
```
docker compose up
```

* Access the Web UI by visiting http://0.0.0.0:3000/
* Access Mailhog inbox by visiting http://0.0.0.0:8025/ (You will receive all emails going out of the application here)

### 5. Stop the App
```
docker compose down
```

## Run Unit Tests
### 1. Build docker images
```
docker compose build
```

### 2. Prepare the Database with test config
```
docker compose run --rm rails bundle exec rails db:chatwoot_prepare RAILS_ENV=test
```

### 3. Run the tests
```
docker compose run --rm -e RAILS_ENV=test rails bundle exec rspec --profile=10 --format documentation
```

## Daily Development Commands

```
# Start development environment
docker compose up

# View logs
docker compose logs -f rails

# Access Rails console
docker compose exec rails bundle exec rails console

# Run migrations
docker compose exec rails bundle exec rails db:migrate

# Install new gems
docker compose exec rails bundle install

# Restart a service
docker compose restart rails

# Stop all services
docker compose down

# Stop and remove volumes (reset database)
docker compose down -v
```
​

## Troubleshooting
If there is an update to any of the following:

* dockerfile
* gemfile
* package.json
* schema change

Make sure to rebuild the containers and run db:reset.

```
docker compose down
docker compose build
docker compose run --rm rails bundle exec rails db:reset
docker compose up
```

## Deployment

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).
