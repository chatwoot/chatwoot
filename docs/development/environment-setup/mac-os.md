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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

### Install Git

```bash
brew update
brew install git
```

### Install RVM

```bash
curl -L https://get.rvm.io | bash -s stable
```

### Install Ruby

Chatwoot APIs are built on Ruby on Rails, you need install ruby 2.7.2

If you are using `rvm` :

```bash
rvm install ruby-2.7.2
rvm use 2.7.2
source ~/.rvm/scripts/rvm
```

If you are using `rbenv` to manage ruby versions do :

```bash
rbenv install 2.7.2
```

`rbenv` identifies the ruby version from `.ruby-version` file on the root of the project and loads it automatically.

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

The database used in Chatwoot is PostgreSQL.

1) Install PostgresApp (https://postgresapp.com). This is easiest way to get started with PostgreSQL on mac.

or

2) Use the following commands to install postgres.

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

Start the redis service.

```bash
brew services start redis
```

### Install imagemagick
Chatwoot uses `imagemagick` library to resize images for showing previews and smaller size based on context.

```bash
brew install imagemagick
```

You can read more on installing imagemagick from source from [here](https://imagemagick.org/script/download.php).

### Install Docker

This is an optional step. Those who are doing development can install docker from [Docker Desktop](https://www.docker.com/products/docker-desktop).
