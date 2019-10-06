<p align="center">
  <img src=".github/woot-logo.svg" alt="Woo-logo" width="240">
  <div align="center">Opensource alternative to Intercom, Zendesk, Drift, Crisp etc.</div>
</p>

___

![CircleCI Badge](https://img.shields.io/circleci/build/github/chatwoot/chatwoot)
![Dependencies](https://img.shields.io/david/chatwoot/chatwoot)
![Github Issues](https://img.shields.io/github/issues/chatwoot/chatwoot)
![License](https://img.shields.io/github/license/chatwoot/chatwoot)
[![Maintainability](https://api.codeclimate.com/v1/badges/80f9e1a7c72d186289ad/maintainability)](https://codeclimate.com/github/chatwoot/chatwoot/maintainability)
![Commits-per-month](https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot)
![ChatUI progess](https://chatwoot.com/images/dashboard-screen.png)

## Quick Setup

### Install JS dependencies

``` bash
yarn install
```

### Install ImageMagik

```bash
brew install imagemagick
```

### Setup rails server

```bash
# install ruby dependencies
bundle

# copy config
cp shared/config/database.yml config/database.yml
cp shared/config/application.yml config/application.yml

# copy frontend env file
cp .env.sample .env

# run db migrations
bundle exec rake db:create
bundle exec rake db:reset

# fireup the server
foreman start -f Procfile.dev
```

### Login with credentials

```bash
http://localhost:3000
user name: larry@google.com
password: 123456
```

### Detailed documentation

Detailed documentation is available at [docs.chatwoot.com](https://docs.chatwoot.com)

## Contributors ✨

Thanks goes to all these [wonderful people](https://github.com/chatwoot/chatwoot/blob/master/docs/contributors.md):

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind welcome!

*Chatwoot* &copy; 2017-2019, ThoughtWoot Inc - Released under the MIT License.
