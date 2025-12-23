# selectize-rails [![Gem Version](https://badge.fury.io/rb/selectize-rails.png)](http://badge.fury.io/rb/selectize-rails)

selectize-rails provides the [selectize.js](https://selectize.github.io/selectize.js/)
plugin as a Rails engine to use it within the asset pipeline.

## Installation

Add this to your Gemfile:

```ruby
gem "selectize-rails"
```

and run `bundle install`.

## Usage

In your `application.js`, include the following:

```js
//= require selectize
```

In your `application.css`, include the following:

```css
 *= require selectize
 *= require selectize.default
```

Or if you like, you could use import instead

```sass
@import 'selectize'
@import 'selectize.bootstrap3'
```

### Themes

To include additional theme's you can replace the `selectize.default` for one of the [theme files](https://github.com/selectize/selectize.js/tree/master/dist/css)


## Examples

See the [demo page](http://selectize.github.io/selectize.js/) for examples how to use the plugin

## Changes

| Version    | Notes                                                       |
| ----------:| ----------------------------------------------------------- |
|   0.12.5   | Update to v0.12.5 of selectize.js                           |
|   0.12.4.1 | Moved css files to scss to be able to use `@import`         |
|   0.12.4   | Update to v0.12.4 of selectize.js                           |
|   0.12.3   | Update to v0.12.3 of selectize.js                           |
|   0.12.2   | Update to v0.12.2 of selectize.js                           |
|   0.12.1   | Update to v0.12.1 of selectize.js                           |
|   0.12.0   | Update to v0.12.0 of selectize.js                           |
|   0.11.2   | Update to v0.11.2 of selectize.js                           |
|   0.11.0   | Update to v0.11.0 of selectize.js                           |

[older](CHANGELOG.md)

## License

* The [selectize.js](http://selectize.github.io/selectize.js/) plugin is licensed under the
[Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)
* The [selectize-rails](https://github.com/manuelvanrijn/selectize-rails) project is
 licensed under the [MIT License](http://opensource.org/licenses/mit-license.html)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
