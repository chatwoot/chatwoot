rspec-rails supports integration with Capybara out of the box by adding
its Capybara::DSL (visit/page) and Capybara::RSpecMatchers to the
examples in the applicable directories.

## Capybara::DSL

Adds the `visit` and `page` methods, which work together to simulate a
GET request and provide access to the result (via `page`).

Capybara::DSL is added to examples in:

* spec/features

## Capybara::RSpecMatchers

Exposes matchers used to specify expected HTML content (e.g. `should_not have_selector` will work correctly).

Capybara::RSpecMatchers is added to examples in:

* spec/features
* spec/controllers
* spec/views
* spec/helpers
* spec/mailers

## Upgrading to Capybara-3.x

Consult the official [Upgrading from Capybara 2.x to 3.x](https://github.com/teamcapybara/capybara/blob/master/UPGRADING.md#upgrading-from-capybara-2x-to-3x) guide.
