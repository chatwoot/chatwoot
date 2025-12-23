# Releases

## v2.1.1

  - Prevent `Rack::Session::Pool` from recreating deleted sessions [CVE-2025-46336](https://github.com/rack/rack-session/security/advisories/GHSA-9j94-67jr-4cqj).

## v2.1.0

  - Improved compatibility with Ruby 3.3+ and Rack 3+.
  - Add support for cookie option `partitioned`.
  - Introduce `assume_ssl` option to allow secure session cookies through insecure proxy.

## v2.0.0

  - Initial migration of code from Rack 2, for Rack 3 release.

## v1.0.2

  - Fix missing `rack/session.rb` file.

## v1.0.1

  - Pin to `rack < 3`.

## v1.0.0

  - Empty shim release for Rack 2.
