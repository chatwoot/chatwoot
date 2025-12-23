# Ruby SAML Migration Guide

## Updating from 1.17.x to 1.18.0

Version `1.18.0` changes the way the toolkit validates SAML signatures. There is a new order
how validation happens in the toolkit and also the toolkit by default will check malformed doc
when parsing a SAML Message (`settings.check_malformed_doc`).

The SignedDocument class defined at xml_security.rb experienced several changes.
We don't expect compatibilty issues if you use the main methods offered by ruby-saml, but if you use a fork or customized usage, is possible that you need to adapt your code.

## Updating from 1.12.x to 1.13.0

Version `1.13.0` adds `settings.idp_sso_service_binding` and `settings.idp_slo_service_binding`, and
deprecates `settings.security[:embed_sign]`. If specified, new binding parameters will be used in place of `:embed_sign`
to determine how to handle SAML message signing (`HTTP-POST` embeds signature and `HTTP-Redirect` does not.)

In addition, the `IdpMetadataParser#parse`, `#parse_to_hash` and `#parse_to_array` methods now retrieve
`idp_sso_service_binding` and `idp_slo_service_binding`.

Lastly, for convenience you may now use the Symbol aliases `:post` and `:redirect` for any `settings.*_binding` parameter.

## Upgrading from 1.11.x to 1.12.0

Version `1.12.0` adds support for gcm algorithm and
change/adds specific error messages for signature validations

`idp_sso_target_url` and `idp_slo_target_url` attributes of the Settings class deprecated
in favor of `idp_sso_service_url` and `idp_slo_service_url`. The `IdpMetadataParser#parse`,
`#parse_to_hash` and `#parse_to_array` methods now retrieve SSO URL and SLO URL endpoints with
`idp_sso_service_url` and `idp_slo_service_url` (previously `idp_sso_target_url` and
`idp_slo_target_url` respectively).

## Upgrading from 1.10.x to 1.11.0

Version `1.11.0` deprecates the use of `settings.issuer` in favour of `settings.sp_entity_id`.
There are two new security settings: `settings.security[:check_idp_cert_expiration]` and
`settings.security[:check_sp_cert_expiration]` (both false by default) that check if the
IdP or SP X.509 certificate has expired, respectively.

Version `1.10.2` includes the `valid_until` attribute in parsed IdP metadata.

Version `1.10.1` improves Ruby 1.8.7 support.

## Upgrading from 1.9.0 to 1.10.0

Version `1.10.0` improves IdpMetadataParser to allow parse multiple IDPSSODescriptor,
Add Subject support on AuthNRequest to allow SPs provide info to the IdP about the user
to be authenticated and updates the format_cert method to accept certs with /\x0d/

## Upgrading from 1.8.0 to 1.9.0

Version `1.9.0` better supports Ruby 2.4+ and JRuby 9.2.0.0. `Settings` initialization
now has a second parameter, `keep_security_settings` (default: false), which saves security
settings attributes that are not explicitly overridden, if set to true.

## Upgrading from 1.7.x to 1.8.0

On Version `1.8.0`, creating AuthRequests/LogoutRequests/LogoutResponses with nil RelayState
param will not generate a URL with an empty RelayState parameter anymore. It also changes
the invalid audience error message.

## Upgrading from 1.6.0 to 1.7.0

Version `1.7.0` is a recommended update for all Ruby SAML users as it includes a fix for
the [CVE-2017-11428](https://www.cvedetails.com/cve/CVE-2017-11428/) vulnerability.

## Upgrading from 1.5.0 to 1.6.0

Version `1.6.0` changes the preferred way to construct instances of `Logoutresponse` and
`SloLogoutrequest`. Previously the _SAMLResponse_, _RelayState_, and _SigAlg_ parameters
of these message types were provided via the constructor's `options[:get_params]` parameter.
Unfortunately this can result in incompatibility with other SAML implementations; signatures
are specified to be computed based on the _sender's_ URI-encoding of the message, which can
differ from that of Ruby SAML. In particular, Ruby SAML's URI-encoding does not match that
of Microsoft ADFS, so messages from ADFS can fail signature validation.

The new preferred way to provide _SAMLResponse_, _RelayState_, and _SigAlg_ is via the
`options[:raw_get_params]` parameter. For example:

```ruby
# In this example `query_params` is assumed to contain decoded query parameters,
# and `raw_query_params` is assumed to contain encoded query parameters as sent by the IDP.
settings = {
  settings.security[:signature_method] = XMLSecurity::Document::RSA_SHA1
  settings.soft = false
}
options = {
  get_params: {
    "Signature" => query_params["Signature"],
  },
  raw_get_params: {
    "SAMLRequest" => raw_query_params["SAMLRequest"],
    "SigAlg" => raw_query_params["SigAlg"],
    "RelayState" => raw_query_params["RelayState"],
  },
}
slo_logout_request = OneLogin::RubySaml::SloLogoutrequest.new(query_params["SAMLRequest"], settings, options)
raise "Invalid Logout Request" unless slo_logout_request.is_valid?
```

The old form is still supported for backward compatibility, but all Ruby SAML users
should prefer `options[:raw_get_params]` where possible to ensure compatibility with
other SAML implementations.

## Upgrading from 1.4.2 to 1.4.3

Version `1.4.3` introduces Recipient validation of SubjectConfirmation elements.
The 'Recipient' value is compared with the settings.assertion_consumer_service_url
value.

If you want to skip that validation, add the :skip_recipient_check option to the
initialize method of the Response object.

Parsing metadata that contains more than one certificate will propagate the
idp_cert_multi property rather than idp_cert. See [signature validation
section](#signature-validation) for details.

## Upgrading from 1.3.x to 1.4.x

Version `1.4.0` is a recommended update for all Ruby SAML users as it includes security improvements.

## Upgrading from 1.2.x to 1.3.x

Version `1.3.0` is a recommended update for all Ruby SAML users as it includes security fixes.
It adds security improvements in order to prevent Signature wrapping attacks.
[CVE-2016-5697](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-5697)

## Upgrading from 1.1.x to 1.2.x

Version `1.2` adds IDP metadata parsing improvements, uuid deprecation in favour of SecureRandom,
refactor error handling and some minor improvements.

There is no compatibility issue detected.

For more details, please review [CHANGELOG.md](CHANGELOG.md).

## Upgrading from 1.0.x to 1.1.x

Version `1.1` adds some improvements on signature validation and solves some namespace conflicts.

## Upgrading from 0.9.x to 1.0.x

Version `1.0` is a recommended update for all Ruby SAML users as it includes security fixes.

Version `1.0` adds security improvements like entity expansion limitation, more SAML message validations, and other important improvements like decrypt support.

### Important Changes

Please note the `get_idp_metadata` method raises an exception when it is not able to fetch the idp metadata, so review your integration if you are using this functionality.

## Upgrading from 0.8.x to 0.9.x

Version `0.9` adds many new features and improvements.

## Upgrading from 0.7.x to 0.8.x

Version `0.8.x` changes the namespace of the gem from `OneLogin::Saml` to `OneLogin::RubySaml`.  Please update your implementations of the gem accordingly.
