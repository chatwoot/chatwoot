# Rails::Dom::Testing

This gem is responsible for comparing HTML doms and asserting that DOM elements are present in Rails applications.
Doms are compared via `assert_dom_equal` and `assert_dom_not_equal`.
Elements are asserted via `assert_dom`, `assert_dom_encoded`, `assert_dom_email` and a subset of the dom can be selected with `css_select`.
The gem is developed for Rails 4.2 and above, and will not work on previous versions.

## Usage

### Dom Assertions

```ruby
assert_dom_equal '<h1>Lingua França</h1>', '<h1>Lingua França</h1>'

assert_dom_not_equal '<h1>Portuguese</h1>', '<h1>Danish</h1>'
```

### Selector Assertions

```ruby
# implicitly selects from the document_root_element
css_select '.hello' # => Nokogiri::XML::NodeSet of elements with hello class

# select from a supplied node. assert_dom asserts elements exist.
assert_dom document_root_element.at('.hello'), '.goodbye'

# elements in CDATA encoded sections can also be selected
assert_dom_encoded '#out-of-your-element'

# assert elements within an html email exists
assert_dom_email '#you-got-mail'
```

The documentation in [selector_assertions.rb](https://github.com/rails/rails-dom-testing/blob/master/lib/rails/dom/testing/assertions/selector_assertions.rb) goes into a lot more detail of how selector assertions can be used.

### HTML versions

By default, assertions will use Nokogiri's HTML4 parser.

If `Rails::Dom::Testing.default_html_version` is set to `:html5`, then the assertions will use
Nokogiri's HTML5 parser. (If the HTML5 parser is not available on your platform, then a
`NotImplementedError` will be raised.)

When testing in a Rails application, the parser default can also be set by setting
`Rails.application.config.dom_testing_default_html_version`.

Some assertions support an `html_version:` keyword argument which can override the default for that
assertion. For example:

``` ruby
# compare DOMs built with the HTML5 parser
assert_dom_equal(expected, actual, html_version: :html5)

# compare DOMs built with the HTML4 parser
assert_dom_not_equal(expected, actual, html_version: :html4)
```

Please see documentation for individual assertions for more details.

## Installation

Add this line to your application's Gemfile:

    gem 'rails-dom-testing'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-dom-testing

## Read more

Under the hood the doms are parsed with Nokogiri, and you'll generally be working with these two classes:
- [`Nokogiri::XML::Node`](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Node)
- [`Nokogiri::XML::NodeSet`](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/NodeSet)

Read more about Nokogiri:
- [Nokogiri](http://nokogiri.org)

## Contributing to Rails::Dom::Testing

Rails::Dom::Testing is work of many contributors. You're encouraged to submit pull requests, propose
features and discuss issues.

See [CONTRIBUTING](CONTRIBUTING.md).

## License
Rails::Dom::Testing is released under the [MIT License](MIT-LICENSE).
