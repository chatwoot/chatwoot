# Tidewave

Tidewave speeds up development with an AI assistant that understands your web application,
how it runs, and what it delivers. Our current release connects your editor's
assistant to your web framework runtime via [MCP](https://modelcontextprotocol.io/).

[See our website](https://tidewave.ai) for more information.

## Installation

You can install Tidewave by adding the `tidewave` gem to the development group in your Gemfile:

```ruby
gem "tidewave", group: :development
```

Tidewave will now run on the same port as your regular Rails application.
In particular, the MCP is located by default at http://localhost:3000/tidewave/mcp.
[You must configure your editor and AI assistants accordingly](https://hexdocs.pm/tidewave/mcp.html).

## Troubleshooting

### Localhost requirement

Tidewave expects your web application to be running on `localhost`. If you are not running on localhost, you may need to set some additional configuration. In particular, you must configure Tidewave to allow `allow_remote_access` and [optionally configure your Rails hosts](https://guides.rubyonrails.org/configuring.html#actiondispatch-hostauthorization). For example, in your `config/environments/development.rb`:

```ruby
config.hosts << "company.local"
config.tidewave.allow_remote_access = true
```

If you want to use Docker for development, you either need to enable the configuration above or automatically redirect the relevant ports, as done by [devcontainers](https://code.visualstudio.com/docs/devcontainers/containers). See our [containars](https://hexdocs.pm/tidewave/containers.html) guide for more information.

### Content security policy

If you have enabled Content-Security-Policy, Tidewave will automatically enable "unsafe-eval" under `script-src` in order for contextual browser testing to work correctly.

### Production Environment

Tidewave is a powerful tool that can help you develop your web application faster and more efficiently. However, it is important to note that Tidewave is not meant to be used in a production environment.

Tidewave will raise an error if it is used in any environment where code reloading is disabled (which typically includes production).

### Web server requirements

Tidewave currently requires a threaded web server like Puma.

## Configuration

You may configure `tidewave` using the following syntax:

```ruby
  config.tidewave.allow_remote_access = true
```

The following options are available:

  * `:allow_remote_access` - Tidewave only allows requests from localhost by default, even if your server listens on other interfaces as well. If you trust your network and need to access Tidewave from a different machine, this configuration can be set to `true`

  * `:preferred_orm` - which ORM to use, either `:active_record` (default) or `:sequel`

## Acknowledgements

A thank you to Yorick Jacquin, for creating [FastMCP](https://github.com/yjacquin/fast_mcp) and implementing the initial version of this project.

## License

Copyright (c) 2025 Dashbit

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
