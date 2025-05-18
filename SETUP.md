# LiveIQ (Modified Chatwoot) Setup Guide

This document provides detailed instructions for setting up and running the LiveIQ application (based on Chatwoot) for development purposes.

## Prerequisites

Ensure you have the following installed on your system:

- **Ruby**: version 3.2.2 or higher
- **Node.js**: version 18.x or higher
- **PostgreSQL**: version 13.x or higher
- **Redis**: version 6.x or higher
- **Yarn**: version 1.x or higher

### System Dependencies (Ubuntu/Debian)

```bash
# Update package lists
sudo apt update

# Install dependencies
sudo apt install -y \
  git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev \
  libncurses5-dev libffi-dev libgdbm-dev \
  postgresql postgresql-contrib redis-server

# Install ImageMagick for image processing
sudo apt install -y imagemagick
```

### System Dependencies (macOS)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install git postgresql redis imagemagick

# Start PostgreSQL and Redis
brew services start postgresql
brew services start redis
```

### Ruby Installation

```bash
# Install rbenv
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install ruby-build
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby
rbenv install 3.2.2
rbenv global 3.2.2

# Verify installation
ruby --version
```

### Node.js Installation

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
source ~/.bashrc

# Install Node.js
nvm install 18
nvm use 18

# Verify installation
node --version
```

## Database Setup

```bash
# Create a PostgreSQL user
sudo -u postgres createuser -P -d liveiq

# Create development and test databases
sudo -u postgres createdb liveiq_development -O liveiq
sudo -u postgres createdb liveiq_test -O liveiq
```

## Application Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/liveiq.git
cd liveiq
```

### 2. Install Ruby Dependencies

```bash
# Install bundler
gem install bundler

# Install Ruby dependencies
bundle install
```

### 3. Install JavaScript Dependencies

```bash
# Install Yarn if not already installed
npm install -g yarn

# Install JavaScript dependencies
yarn install
```

### 4. Configure Environment Variables

```bash
# Copy the sample .env file
cp .env.example .env

# Edit the .env file with your database credentials
nano .env
```

Set the following variables in your .env file:

```
POSTGRES_HOST=localhost
POSTGRES_USERNAME=liveiq
POSTGRES_PASSWORD=your_password
```

### 5. Setup Database

```bash
# Create and migrate the database
bundle exec rails db:setup

# Create required database extensions (run in PostgreSQL console)
sudo -u postgres psql -d liveiq_development -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS hstore; CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'
sudo -u postgres psql -d liveiq_test -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto; CREATE EXTENSION IF NOT EXISTS hstore; CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'
```

## Running the Application

### 1. Start the Rails server

```bash
# Start the Rails server
bundle exec rails s
```

### 2. Start the webpack dev server (in another terminal)

```bash
# Start the webpack server
bundle exec bin/webpack-dev-server
```

### 3. Start Sidekiq for background jobs (in another terminal)

```bash
# Start Sidekiq
bundle exec sidekiq
```

## Accessing the Application

- Open your browser and navigate to `http://localhost:3000`
- Create a new admin account during the first login

## Running Tests

```bash
# Run Ruby tests
bundle exec rspec

# Run JavaScript tests
yarn test
```

## Troubleshooting

### Database Issues

If you encounter database-related errors:

```bash
# Reset the database
bundle exec rails db:drop db:create db:migrate db:seed
```

### JavaScript Issues

If you encounter JavaScript-related errors:

```bash
# Clear node modules and reinstall
rm -rf node_modules
yarn install
```

### Redis Issues

If Redis isn't running correctly:

```bash
# Check if Redis is running
redis-cli ping
```

If it doesn't return "PONG", restart the Redis server:

```bash
# Ubuntu/Debian
sudo service redis-server restart

# macOS
brew services restart redis
```

## Additional Resources

- Original Chatwoot Documentation: [https://www.chatwoot.com/docs/](https://www.chatwoot.com/docs/)
- PostgreSQL Documentation: [https://www.postgresql.org/docs/](https://www.postgresql.org/docs/)
- Ruby on Rails Guides: [https://guides.rubyonrails.org/](https://guides.rubyonrails.org/)

## License

This project is based on Chatwoot and follows the same licensing as the original project. 