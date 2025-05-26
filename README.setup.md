# Chatwoot Local Setup Guide

This guide helps new developers set up Chatwoot locally with working frontend and backend environments.

> ⚠️ **Note:** This guide assumes you're using **macOS** with Homebrew.
> If you're on **Windows or Linux**, please refer to other sources.

---

## 🛠️ Prerequisites

Ensure you have the following installed:

| Tool       | Version (Recommended) | Install Command / Link                           |
| ---------- | --------------------- | ------------------------------------------------ |
| Ruby       | 3.x                   | `brew install ruby`                              |
| Node.js    | 16+                   | `brew install node`                              |
| Yarn       | 1.22+                 | `npm install -g yarn`                            |
| PostgreSQL | 12+                   | `brew install postgresql`                        |
| Redis      | 6+                    | `brew install redis`                             |
| Git        | latest                | `brew install git`                               |
| Docker     | *(optional)*          | [https://www.docker.com](https://www.docker.com) |

To start services (on macOS/Homebrew):

```bash
brew services start postgresql
brew services start redis
```

### 🪟 Windows / 🐧 Linux Users

* Use package managers like `apt`, `choco`, or official installers
* Ensure versions match the requirements above
* See Chatwoot's official guide for distro-specific instructions

---

## 🚀 Backend Setup (Ruby on Rails)

```bash
# Install Ruby dependencies
bundle install

# Setup database
bundle exec rake db:setup

# Start backend server
bundle exec rails s
```

---

## 🌐 Frontend Setup (Vue.js)

```bash
# From the project root
yarn install

# Start frontend server
yarn dev
```

App runs at: [http://localhost:3000](http://localhost:3000)

---

## ✅ Test Functionality

1. Open `http://localhost:3000`
2. Sign up or log in
3. Try:

   * Creating a new inbox
   * Sending a message
   * Switching views and navigating around

---

## 🧯 Troubleshooting Tips

| Issue                          | Fix                                     |
| ------------------------------ | --------------------------------------- |
| `pg_config not found`          | Reinstall PostgreSQL via Homebrew       |
| Redis not running              | `brew services start redis`             |
| Node modules fail to install   | `yarn install --force`                  |
| `webpack-dev-server` not found | `yarn install` again from project root  |
| DB connection errors           | Ensure PostgreSQL and Redis are running |

---

## 📘 Notes

* Use `bundle exec rails console` to open Rails console
* Use `rails db:reset` to clear DB and start fresh
* Logs:

  * Backend: Terminal window running `rails s`
  * Frontend: Terminal running `yarn dev`

---

## 👋 Final Tip

If something fails, double check version requirements, restart Redis/PostgreSQL, and rerun `yarn install` or `bundle install`.