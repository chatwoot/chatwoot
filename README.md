![Woot-logo](.github/woot-logo.png)

Opensource alternative to Intercom, Zendesk, Drift, Crisp etc.

___

![CircleCI Badge](https://img.shields.io/circleci/build/github/chatwoot/chatwoot)
![Dependencies](https://img.shields.io/david/chatwoot/chatwoot)
![Github Issues](https://img.shields.io/github/issues/chatwoot/chatwoot)
![License](https://img.shields.io/github/license/chatwoot/chatwoot)
[![Maintainability](https://api.codeclimate.com/v1/badges/80f9e1a7c72d186289ad/maintainability)](https://codeclimate.com/github/chatwoot/chatwoot/maintainability)
![Commits-per-month](https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot)

![ChatUI progess](https://chatwoot.com/images/dashboard-screen.png)

## Build Setup


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


*Chatwoot* &copy; 2017-2019, ThoughtWoot Inc - Released under the MIT License.

[www.chatwoot.com](https://www.chatwoot.com)
&nbsp;&middot;&nbsp;
GitHub: [@chatwoot](https://github.com/chatwoot)
&nbsp;&middot;&nbsp;
Email: [hello@chatwoot.com](mailto:hello@chatwoot.com)
