# Webpacker

[![Build Status](https://travis-ci.org/rails/webpacker.svg?branch=master)](https://travis-ci.org/rails/webpacker)
[![node.js](https://img.shields.io/badge/node-%3E%3D%2010.17.0-brightgreen.svg)](https://www.npmjs.com/package/@rails/webpacker)
[![Gem](https://img.shields.io/gem/v/webpacker.svg)](https://rubygems.org/gems/webpacker)

Webpacker makes it easy to use the JavaScript pre-processor and bundler
[webpack 4.x.x+](https://webpack.js.org/)
to manage application-like JavaScript in Rails. It coexists with the asset pipeline,
as the primary purpose for webpack is app-like JavaScript, not images, CSS, or
even JavaScript Sprinkles (that all continues to live in app/assets).

However, it is possible to use Webpacker for CSS, images and fonts assets as well,
in which case you may not even need the asset pipeline. This is mostly relevant when exclusively using component-based JavaScript frameworks.

**NOTE:** The master branch now hosts the code for v5.x.x. Please refer to [4-x-stable](https://github.com/rails/webpacker/tree/4-x-stable) branch for 4.x documentation.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

## Table of Contents

- [Prerequisites](#prerequisites)
- [Features](#features)
- [Installation](#installation)
  - [Usage](#usage)
  - [Development](#development)
  - [Webpack Configuration](#webpack-configuration)
  - [Custom Rails environments](#custom-rails-environments)
  - [Upgrading](#upgrading)
- [Integrations](#integrations)
  - [React](./docs/integrations.md#react)
  - [Angular with TypeScript](./docs/integrations.md#angular-with-typescript)
  - [Vue](./docs/integrations.md#vue)
  - [Elm](./docs/integrations.md#elm)
  - [Stimulus](./docs/integrations.md#stimulus)
  - [Svelte](./docs/integrations.md#svelte)
  - [Typescript](./docs/typescript.md)
  - [CoffeeScript](./docs/integrations.md#coffeescript)
  - [Erb](./docs/integrations.md#erb)
- [Paths](#paths)
  - [Resolved](#resolved)
  - [Watched](#watched)
- [Deployment](#deployment)
- [Docs](#docs)
- [Contributing](#contributing)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Prerequisites

- Ruby 2.4+
- Rails 5.2+
- Node.js 10.17.0+
- Yarn 1.x+

## Features

- [webpack 4.x.x](https://webpack.js.org/)
- ES6 with [babel](https://babeljs.io/)
- Automatic code splitting using multiple entry points
- Stylesheets - Sass and CSS
- Images and fonts
- PostCSS - Auto-Prefixer
- Asset compression, source-maps, and minification
- CDN support
- React, Angular, Elm and Vue support out-of-the-box
- Rails view helpers
- Extensible and configurable

## Installation

You can either add Webpacker during setup of a new Rails 5.1+ application
using new `--webpack` option:

```bash
# Available Rails 5.1+
rails new myapp --webpack
```

Or add it to your `Gemfile`:

```ruby
# Gemfile
gem 'webpacker', '~> 5.x'

# OR if you prefer to use master
gem 'webpacker', git: 'https://github.com/rails/webpacker.git'
yarn add https://github.com/rails/webpacker.git
yarn add core-js regenerator-runtime
```

Finally, run the following to install Webpacker:

```bash
bundle
bundle exec rails webpacker:install

# OR (on rails version < 5.0)
bundle exec rake webpacker:install
```

Optional: To fix ["unmet peer dependency" warnings](https://github.com/rails/webpacker/issues/1078),

```bash
yarn upgrade
```

When `package.json` and/or `yarn.lock` changes, such as when pulling down changes to your local environment in a team settings, be sure to keep your NPM packages up-to-date:

```bash
yarn install
```

### Usage

Once installed, you can start writing modern ES6-flavored JavaScript apps right away:

```yml
app/javascript:
  ├── packs:
  │   # only webpack entry files here
  │   └── application.js
  │   └── application.css
  └── src:
  │   └── my_component.js
  └── stylesheets:
  │   └── my_styles.css
  └── images:
      └── logo.svg
```

In `/packs/application.js`, include this at the top of the file:

```js
import 'core-js/stable'
import 'regenerator-runtime/runtime'
```

You can then link the JavaScript pack in Rails views using the `javascript_pack_tag` helper.
If you have styles imported in your pack file, you can link them by using `stylesheet_pack_tag`:

```erb
<%= javascript_pack_tag 'application' %>
<%= stylesheet_pack_tag 'application' %>
```

If you want to link a static asset for `<link rel="prefetch">` or `<img />` tag, you
can use the `asset_pack_path` helper:

```erb
<link rel="prefetch" href="<%= asset_pack_path 'application.css' %>" />
<img src="<%= asset_pack_path 'images/logo.svg' %>" />
```

If you are using new webpack 4 split chunks API, then consider using `javascript_packs_with_chunks_tag` helper, which creates html
tags for a pack and all the dependent chunks.

```erb
<%= javascript_packs_with_chunks_tag 'calendar', 'map', 'data-turbolinks-track': 'reload' %>

<script src="/packs/vendor-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/calendar~runtime-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/calendar-1016838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/map~runtime-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
<script src="/packs/map-16838bab065ae1e314.js" data-turbolinks-track="reload"></script>
```

**Important:** Pass all your pack names when using `javascript_packs_with_chunks_tag`
helper otherwise you will get duplicated chunks on the page.

```erb
<%# DO %>
<%= javascript_packs_with_chunks_tag 'calendar', 'map' %>

<%# DON'T %>
<%= javascript_packs_with_chunks_tag 'calendar' %>
<%= javascript_packs_with_chunks_tag 'map' %>
```

**Note:** In order for your styles or static assets files to be available in your view,
you would need to link them in your "pack" or entry file.

### Development

Webpacker ships with two binstubs: `./bin/webpack` and `./bin/webpack-dev-server`.
Both are thin wrappers around the standard `webpack.js` and `webpack-dev-server.js`
executables to ensure that the right configuration files and environmental variables
are loaded based on your environment.

In development, Webpacker compiles on demand rather than upfront by default. This
happens when you refer to any of the pack assets using the Webpacker helper methods.
This means that you don't have to run any separate processes. Compilation errors are logged
to the standard Rails log.

If you want to use live code reloading, or you have enough JavaScript that on-demand compilation is too slow, you'll need to run `./bin/webpack-dev-server` or `ruby ./bin/webpack-dev-server`. Windows users will need to run these commands
in a terminal separate from `bundle exec rails s`. This process will watch for changes
in the `app/javascript/packs/*.js` files and automatically reload the browser to match.

```bash
# webpack dev server
./bin/webpack-dev-server

# watcher
./bin/webpack --watch --colors --progress

# standalone build
./bin/webpack
```

Once you start this development server, Webpacker will automatically start proxying all
webpack asset requests to this server. When you stop the server, it'll revert back to
on-demand compilation.

You can use environment variables as options supported by
[webpack-dev-server](https://webpack.js.org/configuration/dev-server/) in the
form `WEBPACKER_DEV_SERVER_<OPTION>`. Please note that these environmental
variables will always take precedence over the ones already set in the
configuration file, and that the _same_ environmental variables must
be available to the `rails server` process.

```bash
WEBPACKER_DEV_SERVER_HOST=example.com WEBPACKER_DEV_SERVER_INLINE=true WEBPACKER_DEV_SERVER_HOT=false ./bin/webpack-dev-server
```

By default, the webpack dev server listens on `localhost` in development for security purposes.
However, if you want your app to be available over local LAN IP or a VM instance like vagrant,
you can set the `host` when running `./bin/webpack-dev-server` binstub:

```bash
WEBPACKER_DEV_SERVER_HOST=0.0.0.0 ./bin/webpack-dev-server
```

**Note:** You need to allow webpack-dev-server host as an allowed origin for `connect-src` if you are running your application in a restrict CSP environment (like Rails 5.2+). This can be done in Rails 5.2+ in the CSP initializer `config/initializers/content_security_policy.rb` with a snippet like this:

```ruby
  Rails.application.config.content_security_policy do |policy|
    policy.connect_src :self, :https, 'http://localhost:3035', 'ws://localhost:3035' if Rails.env.development?
  end
```

**Note:** Don't forget to prefix `ruby` when running these binstubs on Windows

### Webpack Configuration

See [docs/webpack](docs/webpack.md) for modifying webpack configuration and loaders.

### Custom Rails environments

Out of the box Webpacker ships with - development, test and production environments in `config/webpacker.yml` however, in most production apps extra environments are needed as part of deployment workflow. Webpacker supports this out of the box from version 3.4.0+ onwards.

You can choose to define additional environment configurations in webpacker.yml,

```yml
staging:
  <<: *default

  # Production depends on precompilation of packs prior to booting for performance.
  compile: false

  # Cache manifest.json for performance
  cache_manifest: true

  # Compile staging packs to a separate directory
  public_output_path: packs-staging
```

or, Webpacker will use production environment as a fallback environment for loading configurations. Please note, `NODE_ENV` can either be set to `production`, `development` or `test`.
This means you don't need to create additional environment files inside `config/webpacker/*` and instead use webpacker.yml to load different configurations using `RAILS_ENV`.

For example, the below command will compile assets in production mode but will use staging configurations from `config/webpacker.yml` if available or use fallback production environment configuration:

```bash
RAILS_ENV=staging bundle exec rails assets:precompile
```

And, this will compile in development mode and load configuration for cucumber environment
if defined in webpacker.yml or fallback to production configuration

```bash
RAILS_ENV=cucumber NODE_ENV=development bundle exec rails assets:precompile
```

Please note, binstubs compiles in development mode however rake tasks
compiles in production mode.

```bash
# Compiles in development mode unless NODE_ENV is specified
./bin/webpack
./bin/webpack-dev-server

# compiles in production mode by default unless NODE_ENV is specified
bundle exec rails assets:precompile
bundle exec rails webpacker:compile
```

### Upgrading

You can run following commands to upgrade Webpacker to the latest stable version. This process involves upgrading the gem and related JavaScript packages:

```bash
bundle update webpacker
rails webpacker:binstubs
yarn upgrade @rails/webpacker --latest
yarn upgrade webpack-dev-server --latest

# Or to install the latest release (including pre-releases)
yarn add @rails/webpacker@next
```

## Integrations

Webpacker ships with basic out-of-the-box integration. You can see a list of available commands/tasks by running `bundle exec rails webpacker`.

Included install integrations:

- [React](./docs/integrations.md#React)
- [Angular with TypeScript](./docs/integrations.md#Angular-with-TypeScript)
- [Vue](./docs/integrations.md#Vue)
- [Elm](./docs/integrations.md#Elm)
- [Svelte](./docs/integrations.md#Svelte)
- [Stimulus](./docs/integrations.md#Stimulus)
- [CoffeeScript](./docs/integrations.md#CoffeeScript)
- [Typescript](./docs/typescript.md)
- [Erb](./docs/integrations.md#Erb)

See [Integrations](./docs/integrations.md) for further details.

## Paths

By default, Webpacker ships with simple conventions for where the JavaScript
app files and compiled webpack bundles will go in your Rails app.
All these options are configurable from `config/webpacker.yml` file.

The configuration for what webpack is supposed to compile by default rests
on the convention that every file in `app/javascript/packs/*`**(default)**
or whatever path you set for `source_entry_path` in the `webpacker.yml` configuration
is turned into their own output files (or entry points, as webpack calls it). Therefore you don't want to put anything inside `packs` directory that you do not want to be
an entry file. As a rule of thumb, put all files you want to link in your views inside
"packs" directory and keep everything else under `app/javascript`.

Suppose you want to change the source directory from `app/javascript`
to `frontend` and output to `assets/packs`. This is how you would do it:

```yml
# config/webpacker.yml
source_path: frontend
source_entry_path: packs
public_output_path: assets/packs # outputs to => public/assets/packs
```

Similarly you can also control and configure `webpack-dev-server` settings from `config/webpacker.yml` file:

```yml
# config/webpacker.yml
development:
  dev_server:
    host: localhost
    port: 3035
```

If you have `hmr` turned to true, then the `stylesheet_pack_tag` generates no output, as you will want to configure your styles to be inlined in your JavaScript for hot reloading. During production and testing, the `stylesheet_pack_tag` will create the appropriate HTML tags.

### Resolved

If you are adding Webpacker to an existing app that has most of the assets inside
`app/assets` or inside an engine, and you want to share that
with webpack modules, you can use the `additional_paths`
option available in `config/webpacker.yml`. This lets you
add additional paths that webpack should lookup when resolving modules:

```yml
additional_paths: ['app/assets']
```

You can then import these items inside your modules like so:

```js
// Note it's relative to parent directory i.e. app/assets
import 'stylesheets/main'
import 'images/rails.png'
```

**Note:** Please be careful when adding paths here otherwise it
will make the compilation slow, consider adding specific paths instead of
whole parent directory if you just need to reference one or two modules

## Deployment

Webpacker hooks up a new `webpacker:compile` task to `assets:precompile`, which gets run whenever you run `assets:precompile`. If you are not using Sprockets, `webpacker:compile` is automatically aliased to `assets:precompile`. Similar to sprockets both rake tasks will compile packs in production mode but will use `RAILS_ENV` to load configuration from `config/webpacker.yml` (if available).

When compiling assets for production on a remote server, such as a continuous integration environment, it's recommended to use `yarn install --frozen-lockfile` to install NPM packages on the remote host to ensure that the installed packages match the `yarn.lock` file.

## Docs

- [Development](https://github.com/rails/webpacker#development)
  - [Webpack](./docs/webpack.md)
  - [Webpack-dev-server](./docs/webpack-dev-server.md)
  - [Environment Variables](./docs/env.md)
  - [Folder Structure](./docs/folder-structure.md)
  - [Assets](./docs/assets.md) - [CSS, Sass and SCSS](./docs/css.md) - [ES6](./docs/es6.md), [Target browsers](./docs/target.md)
    - [Props](./docs/props.md)
    - [Typescript](./docs/typescript.md)
  - [Yarn](./docs/yarn.md)
  - [Misc](./docs/misc.md)
- [Deployment](./docs/deployment.md)
  - [Docker](./docs/docker.md)
  - [Using in Rails engines](./docs/engines.md)
  - [Webpacker on Cloud9](./docs/cloud9.md)
- [Testing](./docs/testing.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [v3 to v4 Upgrade Guide](./docs/v4-upgrade.md)

## Contributing

[![Code Helpers](https://www.codetriage.com/rails/webpacker/badges/users.svg)](https://www.codetriage.com/rails/webpacker)

We encourage you to contribute to Webpacker! See [CONTRIBUTING](CONTRIBUTING.md) for guidelines about how to proceed.

## License

Webpacker is released under the [MIT License](https://opensource.org/licenses/MIT).
