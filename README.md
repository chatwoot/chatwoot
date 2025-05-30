# Project Setup Guide

This guide walks you through setting up [Chatwoot](https://github.com/chatwoot/chatwoot) locally from scratch, assuming no prior experience. It covers installing all tools, setting up environments, running the app, and validating core functionality.

---

## 🔧 Prerequisites

Install the following in order:

### 1. **Homebrew (Mac only)**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. **Git**
```bash
brew install git
```

### 3. **rbenv and Ruby (v3.4.4)**

```bash
brew install rbenv
rbenv init
```

Follow terminal instructions to add `eval "$(rbenv init -)"` to your shell config (`~/.zshrc` or `~/.bashrc`), then:

```bash
rbenv install 3.4.4
rbenv global 3.4.4
ruby -v  # confirm version
```

### 4. **Bundler**
```bash
gem install bundler
```

---

### 5. **PostgreSQL**

```bash
brew install postgresql
brew services start postgresql
```

To create the user and database:

```bash
psql postgres
# then inside psql
CREATE ROLE chatwoot WITH LOGIN CREATEDB PASSWORD 'chatwoot';
\q
```

---

### 6. **Redis**
```bash
brew install redis
brew services start redis
```

Test Redis is working:

```bash
redis-cli ping  # should return "PONG"
```

---

### 7. **Node.js (v20+)**
```bash
brew install node
node -v
```

---

### 8. **Yarn**
```bash
npm install -g yarn
```

---

### 9. **Overmind + Tmux**
Overmind is used to run multiple services at once.

```bash
brew install tmux
brew install overmind
```

---

## 🚀 Project Setup (Backend + Frontend)

### 1. **Clone your forked repository**
```bash
git clone https://github.com/YOUR_USERNAME/chatwoot.git
cd chatwoot
```

### 2. **Install Ruby dependencies**
```bash
bundle install
```

### 3. **Environment variables**
```bash
cp .env.example .env
```

### 4. **Setup Database**
```bash
bin/rails db:setup
bin/rails db:seed
```

---

### 5. **Install JS dependencies**
```bash
yarn install
yarn add -D sass-embedded  # fixes Vite/SASS issue
```

---

## ▶️ Running the Application Locally

Run everything with one command:

```bash
overmind start -f Procfile.dev
```

This will:
- Run the Rails backend on http://localhost:3000
- Run Sidekiq background worker
- Start the Vite frontend server at http://localhost:3036/vite-dev/

---

## 🧪 Test Core Functionality (Manual Admin Setup)

### Step 1: Launch Rails console
```bash
bundle exec rails c
```

### Step 2: Create a user and account
```ruby
user = User.create!(
  name: 'Admin',
  email: 'admin@example.com',
  password: 'Password@123',
  password_confirmation: 'Password@123',
  confirmed_at: Time.now
)

Account.create!(name: 'My Account', users: [user])
```

Go to [http://localhost:3000](http://localhost:3000), login using the admin email/password, and you should now see the Chatwoot dashboard.

---

## ❗ Troubleshooting

### Redis not running?
```bash
redis-cli ping  # no response?
brew services start redis
```

### PostgreSQL issues?
Make sure Postgres is running:
```bash
brew services start postgresql
```

Recheck DB config in `.env` and `config/database.yml`.

### Vite not responding?
```bash
yarn vite
```

If errors, try reinstalling:
```bash
rm -rf node_modules yarn.lock .yarn
yarn install
```

### Overmind command not found?
```bash
brew install overmind
```

### Can’t push to GitHub?
Use a **Personal Access Token** (PAT) instead of password:
```bash
git remote set-url origin https://<YOUR_PAT>@github.com/Arbaz8888/chatwoot.git
```

Then push your branch:
```bash
git push -u origin setup-docs
```

---

## ✅ You’re Done!

At this point, the full app should be running and accessible. You can now begin development and PR workflows per assessment instructions.

---
