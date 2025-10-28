# Chatwoot Development Environment Setup

## Current Status ✅
- ✅ Git repository initialized with proper remotes
- ✅ Checked out to `develop` branch (latest development code)
- ✅ Node.js dependencies installed with pnpm
- ✅ Git remotes configured:
  - `origin`: https://github.com/hienhoceo-dpsmedia/chatwoot.git (your fork)
  - `upstream`: https://github.com/chatwoot/chatwoot.git (official repo)

## 🔧 Remaining Setup Steps

### 1. Install Ruby 3.4.4
Ruby is required for the backend (Rails) part of Chatwoot.

#### Option A: RubyInstaller (Recommended for Windows)
1. Download RubyInstaller from: https://rubyinstaller.org/downloads/
2. Download "Ruby+Devkit 3.4.4-1 (x64)"
3. Run the installer and follow the prompts
4. When asked about MSYS2, select option 3 (install MSYS2 toolchain)
5. After installation, restart your terminal/VSCode

#### Option B: Using Chocolatey (Admin required)
```powershell
# Run PowerShell as Administrator
choco install ruby --version 3.4.4
```

#### Option C: Using WSL (Linux Subsystem)
```powershell
# Install WSL first, then:
wsl --install
# In WSL terminal:
sudo apt update
sudo apt install ruby-full build-essential
```

### 2. Install PostgreSQL Database
Chatwoot uses PostgreSQL as its database.

#### Option A: Docker (Easiest)
```powershell
docker run --name chatwoot-postgres -e POSTGRES_PASSWORD=chatwoot -p 5432:5432 -d postgres:15
```

#### Option B: Local Installation
Download and install PostgreSQL from: https://www.postgresql.org/download/windows/

### 3. Install Redis
Chatwoot uses Redis for caching and background jobs.

#### Option A: Docker (Easiest)
```powershell
docker run --name chatwoot-redis -p 6379:6379 -d redis:7
```

#### Option B: Windows Subsystem for Linux (WSL)
```powershell
wsl --install
# In WSL:
sudo apt update
sudo apt install redis-server
```

### 4. Complete Ruby Setup
After installing Ruby, install Bundler and gems:

```bash
# Install bundler
gem install bundler

# Install Ruby dependencies
bundle install
```

### 5. Database Setup
```bash
# Create and setup the database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 6. Environment Configuration
```bash
# Copy environment file
cp .env.example .env

# Edit .env file with your database settings
# The defaults should work with the Docker setup above
```

### 7. Start the Development Server
```bash
# Start all services (web server, worker, etc.)
foreman start -f Procfile.dev
```

## 🚀 Development Workflow

### Creating a Feature Branch
```bash
# Make sure your develop branch is up to date
git checkout develop
git pull upstream develop

# Create a new feature branch
git checkout -b feature/your-feature-name
```

### Making Changes
1. Make your code changes
2. Run tests: `bundle exec rspec`
3. Check code style: `bundle exec rubocop`
4. Commit your changes with clear messages

### Pushing and Creating Pull Request
```bash
# Push to your fork
git push origin feature/your-feature-name

# Create a pull request on GitHub
# Go to: https://github.com/chatwoot/chatwoot/compare/develop...hienhoceo-dpsmedia:your-feature-name
```

### Keeping Your Fork Updated
```bash
git checkout develop
git pull upstream develop
git push origin develop
```

## 📁 Important Files and Directories

- `app/` - Main application code (Rails + Vue.js)
- `db/` - Database migrations and seeds
- `spec/` - Test files
- `config/` - Configuration files
- `public/` - Static assets
- `lib/` - Library code and utilities

## 🛠️ Useful Commands

```bash
# Run Rails console
bin/rails console

# Run database migrations
bin/rails db:migrate

# Run tests
bundle exec rspec

# Check code style
bundle exec rubocop

# Start only the web server
bin/rails server

# Start background jobs
bundle exec sidekiq

# View logs
tail -f log/development.log
```

## 🔍 Troubleshooting

### Node.js Version Warning
You may see a warning about Node.js version. Chatwoot recommends Node.js 23.x, but 22.x should work fine for development.

### Ruby Version Issues
Make sure you have exactly Ruby 3.4.4 installed, as specified in `.ruby-version`.

### Database Connection Issues
Ensure PostgreSQL and Redis are running and accessible on the default ports (5432 for PostgreSQL, 6379 for Redis).

### Bundle Install Issues
If you encounter issues during `bundle install`, try:
```bash
bundle clean --force
bundle install
```

## 📚 Additional Resources

- [Chatwoot Documentation](https://www.chatwoot.com/docs)
- [Contributing Guide](https://www.chatwoot.com/docs/contributing-guide)
- [Chatwoot Discord](https://discord.gg/cJXdrwS) for community support

## 🎯 Next Steps

1. Complete the Ruby installation
2. Set up PostgreSQL and Redis (Docker recommended)
3. Run the setup script: `bin/setup`
4. Start the development server
5. Visit http://localhost:3000 to see your Chatwoot instance!

Happy coding! 🚀
