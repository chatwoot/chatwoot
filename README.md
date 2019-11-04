<p align="center">
  <img src=".github/woot-logo.svg" alt="Woo-logo" width="240">
  <div align="center">Opensource alternative to Intercom, Zendesk, Drift, Crisp etc.</div>
</p>

___

<p align="center">
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/80f9e1a7c72d186289ad/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
  <img src="https://img.shields.io/github/license/chatwoot/chatwoot" alt="License">
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month"></p>
</p>

![ChatUI progess](./.github/dashboard-screen.png)

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

# Copy configurations
./configure

# run db migrations
bundle exec rake db:create
bundle exec rake db:reset

# fireup the server
foreman start -f Procfile.dev
```

### Login with credentials

```bash
http://localhost:3000
user name: john@acme.inc
password: 123456
```

## Detailed documentation

Detailed documentation is available at [www.chatwoot.com/docs](https://www.chatwoot.com/docs)

## Contributors ✨

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2019, ThoughtWoot Inc - Released under the MIT License.
