# OmniAuth SAML

[![Gem Version](http://img.shields.io/gem/v/omniauth-saml.svg)][gem]
[![Ruby](https://github.com/omniauth/omniauth-saml/actions/workflows/ruby.yml/badge.svg)](https://github.com/omniauth/omniauth-saml/actions/workflows/ruby.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/749e17b553ea944522c1/maintainability)][codeclimate]
[![Coverage Status](http://img.shields.io/coveralls/omniauth/omniauth-saml.svg)][coveralls]

[gem]: https://rubygems.org/gems/omniauth-saml
[codeclimate]: https://codeclimate.com/github/omniauth/omniauth-saml/maintainability
[coveralls]: https://coveralls.io/r/omniauth/omniauth-saml

A generic SAML strategy for OmniAuth available under the [MIT License](LICENSE.md)

https://github.com/omniauth/omniauth-saml

## Requirements

* [OmniAuth](http://www.omniauth.org/) 2.1+
* Ruby 3.1.x+

## Versioning

We tag and release gems according to the [Semantic Versioning](http://semver.org/) principle. In addition to the guidelines of Semantic Versioning, we follow a further guideline that otherwise backwards-compatible dependency upgrades for security reasons should generally be cause for a MINOR version upgrade as opposed to a PATCH version upgrade. Backwards-incompatible dependency upgrades for security reasons should still result in a MAJOR version upgrade for this library.

## Usage

Use the SAML strategy as a middleware in your application:

```ruby
require 'omniauth'
use OmniAuth::Strategies::SAML,
  :assertion_consumer_service_url     => "consumer_service_url",
  :sp_entity_id                       => "sp_entity_id",
  :idp_sso_service_url                => "idp_sso_service_url",
  :idp_sso_service_url_runtime_params => {:original_request_param => :mapped_idp_param},
  :idp_cert                           => "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----",
  :idp_cert_multi                     => {
                                           :signing => ["-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----", "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----", ...],
                                           :encryption => []
                                         },
  :idp_cert_fingerprint               => "E7:91:B2:E1:...",
  :name_identifier_format             => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
```

or in your Rails application:

in `Gemfile`:

```ruby
gem 'omniauth-saml'
```

and in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml,
    :assertion_consumer_service_url     => "consumer_service_url",
    :sp_entity_id                       => "rails-application",
    :idp_sso_service_url                => "idp_sso_service_url",
    :idp_sso_service_url_runtime_params => {:original_request_param => :mapped_idp_param},
    :idp_cert                           => "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----",
    :idp_cert_multi                     => {
                                             :signing => ["-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----", "-----BEGIN CERTIFICATE-----\n...-----END CERTIFICATE-----", ...],
                                             :encryption => []
                                           },
    :idp_cert_fingerprint               => "E7:91:B2:E1:...",
    :name_identifier_format             => "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
end
```

For IdP-initiated SSO, users should directly access the IdP SSO service URL. Set the `href` of your application's login link to the value of `idp_sso_service_url`. For SP-initiated SSO, link to `/auth/saml`.

A `OneLogin::RubySaml::Response` object is added to the `env['omniauth.auth']` extra attribute, so we can use it in the controller via `env['omniauth.auth'].extra.response_object`

## SP Metadata

The service provider metadata used to ease configuration of the SAML SP in the IdP can be retrieved from `http://example.com/auth/saml/metadata`. Send this URL to the administrator of the IdP.

Note that when [integrating with Devise](#devise-integration), the URL path will be scoped according to the name of the Devise resource.  For example, if the app's user model calls `devise_for :users`, the metadata URL will be `http://example.com/users/auth/saml/metadata`.

## Options

* `:assertion_consumer_service_url` - The URL at which the SAML assertion should be
  received. If not provided, defaults to the OmniAuth callback URL (typically
  `http://example.com/auth/saml/callback`). Optional.

* `:sp_entity_id` - The name of your application. Some identity providers might need this
  to establish the identity of the service provider requesting the login. **Required**.

* `:idp_sso_service_url` - The URL to which the authentication request should be sent.
  This would be on the identity provider. **Required**.

* `:idp_slo_service_url` - The URL to which the single logout request and response should
  be sent. This would be on the identity provider. Optional.

* `:idp_slo_session_destroy` - A proc that accepts up to two parameters (the rack environment, and the session),
  and performs whatever tasks are necessary to log out the current user from your application.
  See the example listed under "Single Logout." Defaults to calling `#clear` on the session. Optional.

* `:slo_default_relay_state` - The value to use as default `RelayState` for single log outs. The
  value can be a string, or a `Proc` (or other object responding to `call`). The `request`
  instance will be passed to this callable if it has an arity of 1. If the value is a string,
  the string will be returned, when the `RelayState` is called. Optional.

* `:idp_sso_service_url_runtime_params` - A dynamic mapping of request params that exist
  during the request phase of OmniAuth that should to be sent to the IdP after a specific
  mapping. So for example, a param `original_request_param` with value `original_param_value`,
  could be sent to the IdP on the login request as `mapped_idp_param` with value
  `original_param_value`. Optional.

* `:idp_cert` - The identity provider's certificate in PEM format. Takes precedence
  over the fingerprint option below. This option or `:idp_cert_multi` or `:idp_cert_fingerprint` must
  be present.
  
* `:idp_cert_multi` - Multiple identity provider certificates in PEM format. Takes precedence
over the fingerprint option below. This option `:idp_cert` or `:idp_cert_fingerprint` must
be present.

* `:idp_cert_fingerprint` - The SHA1 fingerprint of the certificate, e.g.
  "90:CC:16:F0:8D:...". This is provided from the identity provider when setting up
  the relationship. This option or `:idp_cert` or `:idp_cert_multi` MUST be present.

* `:name_identifier_format` - Used during SP-initiated SSO. Describes the format of
  the username required by this application. If you need the email address, use
  "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress". See
  http://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf section 8.3 for
  other options. Note that the identity provider might not support all options.
  If not specified, the IdP is free to choose the name identifier format used
  in the response. Optional.

* `:request_attributes` - Used to build the metadata file to inform the IdP to send certain attributes
  along with the SAMLResponse messages. Defaults to requesting `name`, `first_name`, `last_name` and `email`
  attributes. See the `OneLogin::RubySaml::AttributeService` class in the [Ruby SAML gem](https://github.com/onelogin/ruby-saml) for the available options for each attribute. Set to `{}` to disable this from metadata.

* `:attribute_service_name` - Name for the attribute service. Defaults to `Required attributes`.

* `:attribute_statements` - Used to map Attribute Names in a SAMLResponse to
  entries in the OmniAuth [info hash](https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).
  For example, if your SAMLResponse contains an Attribute called 'EmailAddress',
  specify `{:email => ['EmailAddress']}` to map the Attribute to the
  corresponding key in the info hash.  URI-named Attributes are also supported, e.g.
  `{:email => ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']}`.
  *Note*: All attributes can also be found in an array under `auth_hash[:extra][:raw_info]`,
  so this setting should only be used to map attributes that are part of the OmniAuth info hash schema.

* `:uid_attribute` - Attribute that uniquely identifies the user. If unset, the name identifier returned by the IdP is used.

* See the `OneLogin::RubySaml::Settings` class in the [Ruby SAML gem](https://github.com/onelogin/ruby-saml) for additional supported options.

## IdP Metadata

You can use the `OneLogin::RubySaml::IdpMetadataParser` to configure some options:

```ruby
require 'omniauth'
idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
idp_metadata = idp_metadata_parser.parse_remote_to_hash("http://idp.example.com/saml/metadata")

# or, if you have the metadata in a String:
# idp_metadata = idp_metadata_parser.parse_to_hash(idp_metadata_xml)

use OmniAuth::Strategies::SAML,
  idp_metadata.merge(
    :assertion_consumer_service_url => "consumer_service_url",
    :sp_entity_id                   => "sp_entity_id"
  )
```

See the [Ruby SAML gem's README](https://github.com/onelogin/ruby-saml#metadata-based-configuration) for more details.

## Devise Integration

Straightforward integration with [Devise](https://github.com/plataformatec/devise), the widely-used authentication solution for Rails.

In `config/initializers/devise.rb`:

```ruby
Devise.setup do |config|
  config.omniauth :saml,
    idp_cert_fingerprint: 'fingerprint',
    idp_sso_service_url: 'idp_sso_service_url'
end
```

Then follow Devise's general [OmniAuth tutorial](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview), replacing references to `facebook` with `saml`.

## Single Logout

Single Logout can be Service Provider initiated or Identity Provider initiated.

For SP initiated logout, the `idp_slo_service_url` option must be set to the logout url on the IdP,
and users directed to `user_saml_omniauth_authorize_path + '/spslo'` after logging out locally. For
IdP initiated logout, logout requests from the IdP should go to `/auth/saml/slo` (this can be
advertised in metadata by setting the `single_logout_service_url` config option).

When using Devise as an authentication solution, the SP initiated flow can be integrated
in the `SessionsController#destroy` action.

For this to work it is important to preserve the `saml_uid` and `saml_session_index` value before Devise
clears the session and redirect to the `/spslo` sub-path to initiate the single logout.

Example `destroy` action in `sessions_controller.rb`:

```ruby
class SessionsController < Devise::SessionsController
  # ...

  def destroy
    # Preserve the saml_uid and saml_session_index in the session
    saml_uid = session['saml_uid']
    saml_session_index = session['saml_session_index']
    super do
      session['saml_uid'] = saml_uid
      session['saml_session_index'] = saml_session_index
    end
  end

  # ...

  def after_sign_out_path_for(_)
    if session['saml_uid'] && session['saml_session_index'] && SAML_SETTINGS.idp_slo_service_url
      user_saml_omniauth_authorize_path + "/spslo"
    else
      super
    end
  end
end
```

By default, omniauth-saml attempts to log the current user out of your application by clearing the session.
This may not be enough for some authentication solutions (e.g. [Clearance](https://github.com/thoughtbot/clearance/)).
Instead, you may set the `:idp_slo_session_destroy` option to a proc that performs the necessary logout tasks.

Example `:idp_slo_session_destroy` setting for Clearance compatibility:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :saml, idp_slo_session_destroy: proc { |env, _session| env[:clearance].sign_out }, ...
end
```

## Authors

Authored by [Rajiv Aaron Manglani](http://www.rajivmanglani.com/), Raecoo Cao, Todd W Saxton, Ryan Wilcox, Steven Anderson, Nikos Dimitrakopoulos, Rudolf Vriend and [Bruno Pedro](http://brunopedro.com/).
