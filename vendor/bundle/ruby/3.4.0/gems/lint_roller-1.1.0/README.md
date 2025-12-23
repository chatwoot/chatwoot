# lint_roller - A plugin specification for linters

`lint_roller` is an itty-bitty plugin API for code analysis tools like linters
and formatters. It provides plugins for those tools to load extensions and
specify custom rulesets.

(As of this release, only [Standard
Ruby](https://github.com/standardrb/standard) supports `lint_roller` plugins,
but we think [RuboCop](https://github.com/rubocop/rubocop) could add support and
most plugins would be compatible with both `rubocop` and `standardrb`.
Additionally, there's nothing that would prevent other tools like
[rufo](https://github.com/ruby-formatter/rufo) from adopting it.)

## How to make a plugin

If you want to make a plugin, the first thing you should do is extend
[LintRoller::Plugin](/lib/lint_roller/plugin.rb) with a custom class. Let's take
this example plugin for banana-related static analysis:

```ruby
module BananaRoller
  class Plugin < LintRoller::Plugin
    # `config' is a Hash of options passed to the plugin by the user
    def initialize(config = {})
      @alternative = config["alternative"] ||= "chocolate"
    end

    def about
      LintRoller::About.new(
        name: "banana_roller",
        version: "1.0", # or, in a gem, probably BananaRoller::VERSION
        homepage: "https://github.com/example/banana_roller",
        description: "Configuration of banana-related code"
      )
    end

    # `context' is an instance of LintRoller::Context provided by the runner
    def supported?(context)
      context.engine == :rubocop
    end

    # `context' is an instance of LintRoller::Context provided by the runner
    def rules(context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: Pathname.new(__dir__).join("../../config/default.yml")
      )
    end
  end
end
```

And that's pretty much it. Just a declarative way to identify your plugin,
detect whether it supports the given
[LintRoller::Context](/lib/lint_roller_context.rb) (e.g. the current `runner`
and `engine` and their respective `_version`s), for which the plugin will
ultimately its configuration as a [LintRoller::Rules](/lib/lint_roller/rules.rb)
object.

## Packaging a plugin in a gem

In order for a formatter to use your plugin, it needs to know what path to
require as well as the name of the plugin class to instantiate and invoke.

To make this work seamlessly for your users without additional configuration of
their own, all you need to do is specify a metadata attribute called
`default_lint_roller_plugin` in your gemspec.

Taking [standard-custom](https://github.com/standardrb/standard-custom) as an
example, its gemspec contains:

```ruby
Gem::Specification.new do |spec|
  # …
  spec.metadata["default_lint_roller_plugin"] = "Standard::Custom::Plugin"
  # …
end
```

Because gem specs are loaded by RubyGems and Bundler very early, remember to
specify the plugin as a string representation of the constant, as load order
usually matters, and most tools will need to be loaded before any custom
extensions. Hence, `"Standard::Custom::Plugin"` instead of
`Standard::Custom::Plugin`.

## Using your plugin

Once you've made your plugin, here's how it's configured from a Standard Ruby
`.standard.yml` file.

### If your plugin is packaged as a gem

Packaging your plugin in a gem is the golden path, both because distributing
code via [RubyGems.org](https://rubygems.org) is very neat, but also because it
makes the least work for your users.

If your gem name is `banana_roller` and you've set
`spec.metadata["default_lint_roller_plugin"]` to `"BananaRoller::Plugin"`, then
your users could just add this to their `.standard.yml` file:

```yaml
plugins:
  - banana_roller
```

And that's it! During initialization, `standardrb` will `require
"banana_roller"` and know to call `BananaRoller::Plugin.new(config)` to
instantiate it.

### If your plugin ISN'T in a gem

If you're developing a plugin for internal use or in conjunction with a single
project, you may want it to live in the same repo as opposed to packaging it in
a gem.

To do this, then—in lieu of a gem name—provide the path you want to be required
as its name, and (since there is no `spec.metadata` to learn of your plugin's
class name), specify it as an option on the plugin:

```yaml
plugins:
  - lib/banana_roller/plugin:
      plugin_class_name: BananaRoller::Plugin
```

(Be careful with the indentation here! Any configuration under a plugin must be
indented in order for it to be parsed as a hash under the
`"lib/banana_roller/plugin"` key.)

Additionally, if you want the plugin's name to make more sense, you can give
it whatever name you like in the configuration and specify the `require_path`
explicitly:

```yaml
plugins:
  - banana_roller:
      require_path: lib/banana_roller/plugin
      plugin_class_name: BananaRoller::Plugin
```

### Passing user configuration to the plugin

When a `LintRoller::Plugin` is instantiated, users can pass a configuration hash
that tells your plugin how to behave.

To illustrate how this works in Standard Ruby, anything passed as a hash beneath
a plugin will be passed to the class's `initialize` method:

```yaml
plugins:
  - apple_roller
  - banana_roller:
      require_path: lib/banana_roller/plugin
      plugin_class_name: BananaRoller::Plugin
      alternative: "apples"
  - orange_roller:
      rind: false
```

In the above case, `apple_roller`'s plugin class will be instantiated with
`new({})`, `banana_roller` will get all 3 of those parameters passed
`BananaRoller::Plugin.new({require_path…})`, and `orange_roller`'s class will be
called with `new({rind: false})`.

## Code of Conduct

This project follows Test Double's [code of
conduct](https://testdouble.com/code-of-conduct) for all community interactions,
including (but not limited to) one-on-one communications, public posts/comments,
code reviews, pull requests, and GitHub issues. If violations occur, Test Double
will take any action they deem appropriate for the infraction, up to and
including blocking a user from the organization's repositories.
