# Breaking changes for older versions

The breaking changes for the previous major release are listed in the main [README](README.md).
The breaking changes for older major releases are listed below.

### Breaking change notice for version 8.0.0

Version 7.0.0 introduced ApiVersion, and known versions were hardcoded into the gem. Manually defining API versions is no longer required for versions not listed in the gem. Version 8.0.0 removes the following:
* `ShopifyAPI::ApiVersion::Unstable`
* `ShopifyAPI::ApiVersion::Release`
* `ShopifyAPI::ApiVersion.define_version`

The following methods on `ApiVersion` have been deprecated:
- `.coerce_to_version` deprecated. use `.find_version`
- `.define_known_versions` deprecated. Use `.fetch_known_versions`
- `.clear_defined_versions` deprecated. Use. `.clear_known_versions`
- `.latest_stable_version` deprecated. Use `ShopifyAPI::Meta.admin_versions.find(&:latest_supported)` (this fetches info from Shopify servers. No authentication required.)
- `#name` deprecated. Use `#handle`
- `#stable?` deprecated. Use `#supported?`

Version 8.0.0 introduces a _version lookup mode_. By default, `ShopifyAPI::ApiVersion.version_lookup_mode` is `:define_on_unknown`. When setting the api_version on `Session` or `Base`, the `api_version` attribute takes a version handle (i.e. `'2019-07'` or `:unstable`) and sets an instance of `ShopifyAPI::ApiVersion` matching the handle. When the version_lookup_mode is set to `:define_on_unknown`, any handle will naïvely create a new `ApiVersion` if the version is not in the known versions returned by `ShopifyAPI::ApiVersion.versions`.

To ensure you're setting only known and active versions, call :

```ruby
ShopifyAPI::ApiVersion.version_lookup_mode = :raise_on_unknown
ShopifyAPI::ApiVersion.fetch_known_versions
```

Known and active versions are fetched from https://app.shopify.com/services/apis.json and cached. Trying to use a version outside this cached set will raise an error. To switch back to naïve lookup and create a version if one is not found, call `ShopifyAPI::ApiVersion.version_lookup_mode = :define_on_unknown`.

### Breaking change notice for version 7.0.0

#### Changes to ShopifyAPI::Session
When creating sessions, `api_version`is now required and uses keyword arguments.

To upgrade your use of ShopifyAPI you will need to make the following changes.

```ruby
ShopifyAPI::Session.new(domain, token, extras)
```
is now
```ruby
ShopifyAPI::Session.new(domain: domain, token: token, api_version: api_version, extras: extras)
```
Note `extras` is still optional. The other arguments are required.

```ruby
ShopifyAPI::Session.temp(domain, token, extras) do
  ...
end
```
is now
```ruby
ShopifyAPI::Session.temp(domain: domain, token: token, api_version: api_version) do
  ...
end
```

For example, if you want to use the `2019-04` version, you will create a session like this:
```ruby
session = ShopifyAPI::Session.new(domain: domain, token: token, api_version: '2019-04')
```
if you want to use the `unstable` version, you will create a session like this:
```ruby
session = ShopifyAPI::Session.new(domain: domain, token: token, api_version: :unstable)
```

#### Changes to how to define resources

If you have defined or customized Resources, classes that extend `ShopifyAPI::Base`:
The use of `self.prefix =` has been deprecated; you should now use `self.resource =` and not include `/admin`.
For example, if you specified a prefix like this before:
```ruby
class MyResource < ShopifyAPI::Base
  self.prefix = '/admin/shop/'
end
```
You will update this to:
```ruby
class MyResource < ShopifyAPI::Base
  self.resource_prefix = 'shop/'
end
```

#### URL construction

If you have specified any full paths for API calls in find
```ruby
def self.current(options={})
  find(:one, options.merge(from: "/admin/shop.#{format.extension}"))
end
```
would be changed to

```ruby
def self.current(options = {})
  find(:one, options.merge(
    from: api_version.construct_api_path("shop.#{format.extension}")
  ))
end
```

#### URLs that have not changed

- OAuth URLs for `authorize`, getting the `access_token` from a code, `access_scopes`, and using a `refresh_token` have _not_ changed.
  - get: `/admin/oauth/authorize`
  - post: `/admin/oauth/access_token`
  - get: `/admin/oauth/access_scopes`
- URLs for the merchant’s web admin have _not_ changed. For example: to send the merchant to the product page the url is still `/admin/product/<id>`
