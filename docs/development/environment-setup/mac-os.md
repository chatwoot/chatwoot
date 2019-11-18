---
path: "/docs/installation-guide-mac-os"
title: "Mac OS installation guide"
---

Open terminal app and run the following commands

### Installing the standalone Command Line Tools

Open terminal app and write the code below

```bash
xcode-select --install
```

### Install Homebrew

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Install Git

```bash
brew update
brew install git
```

### Install RVM

You need software-properties-common installed in order to add PPA repositories.

```bash
\curl -L https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
```

### Install Ruby

Chatwoot APIs are built on Ruby on Rails, you need install ruby 2.6.5

```bash
rvm install ruby-2.6.5
```

Use ruby 2.6.5 as default

```bash
rvm use 2.6.5 --default
```

### Install Node.js

Install Node.js from NodeSoure using the following commands

```bash
brew install node
```

### Install yarn

We use `yarn` as package manager

```bash
brew install yarn
```

### Install postgres

The database used in Chatwoot is PostgreSQL. Use the following commands to install postgres.

```bash
brew install postgresql
```

The installation procedure created a user account called postgres that is associated with the default Postgres role. In order to use Postgres, you can log into that account.

```bash
sudo -u postgres psql
```

### Install redis-server

Chatwoot uses Redis server in agent assignments and reporting. To install `redis-server`

```bash
brew install redis
```

Enable Redis to start on system boot.

```bash
launchctl unload ~/Library/LaunchAgents/homebrew.mxcl.redis.plist
```

### Install imagemagick

```bash
brew install imagemagick
```

Next: Read project setup to install project dependencies
