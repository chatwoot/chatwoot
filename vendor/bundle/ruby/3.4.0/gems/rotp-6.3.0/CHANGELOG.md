# Changelog

## [6.3.0](https://github.com/mdp/rotp/compare/v6.2.2...v6.3.0) (2023-08-30)


### Features

* Allow for non-standard provisioning URI params, eg. image/icon ([#91](https://github.com/mdp/rotp/issues/91)) ([45d8aac](https://github.com/mdp/rotp/commit/45d8aac8356424897faf3a0dbda59f88b22df775))

## 6.2.2

- Removed `rjust` from `generate_otp` in favor of more time constant version

## 6.2.1

- Removed old rdoc folder that was triggering a security warning due to an
  old version of JQuery being included in the HTML docs. This has no impact
  on the Ruby library.

## 6.2.0

- Update to expand compatibility with Ruby 3. This was only a change to the
  gemspec, no code changes were necessary.

## 6.1.0

- Fixing URI encoding issues again, breaking out into it's own module
  due to the complexity - closes #100 (@atcruice)
- Add docker-compose.yml to help with easier testing

## 6.0.0

- Dropping support for Ruby <2.3 (Major version bump)
- Fix issue when using --enable-frozen-string-literal Ruby option #95 (jeremyevans)
- URI Encoding fix #94 (ksuh90)
- Update gems (rake, addressable)
- Update Travis tests to include Ruby 2.7

## 5.1.0

- Create `random_base32` to perform `random` to avoid breaking changes
  - Still needed to bump to 5.x due to Base32 cleanup

## 5.0.0

- Clean up base32 implementation to match Google Autheticator
- BREAKING `Base32.random_base32` renamed to random
  - The argument is now byte length vs output string length for more precise bit strengths

## 4.1.0

- Add a digest option to the CLI #83
- Fix provisioning URI is README #82
- Improvements to docs

## 4.0.2

- Fix gemspec requirment for Addressable

## 4.0.1

- Rubocop for style fixes
- Replace deprecated URI.encode with Addressable's version

## 4.0.0

- Simplify API
- Remove support for Ruby < 2.0
- BREAKING CHANGE: Removed optional second argument (`padding`) from:
  - `HOTP#at`
  - `OTP#generate_otp`
  - `TOTP#at`
  - `TOTP#now` (first argument)

## 3.3.1

- Add OpenSSL as a requirement for Ruby 2.5. Fixes #70 & #64
- Allow Base32 with padding. #71
- Prevent verify with drift being negative #69

## 3.3.0

- Add digest algorithm parameter for non SHA1 digests - #62 from @btalbot

## 3.2.0

- Add 'verify_with_drift_and_prior' to prevent prior token use - #58 from @jlfaber

## 3.1.0

- Add Add digits paramater to provisioning URI. #54 from @sbc100

## 3.0.1

- Use SecureRandom. See mdp/rotp/pull/52

## 3.0.0

- Provisioning URL includes issuer label per RFC 5234 See mdp/rotp/pull/51

## 2.1.2

- Remove string literals to prepare immutable strings in Ruby 3.0

## 2.1.1

- Reorder the params for Windows Phone Authenticator - #43

## 2.1.0

- Add a CLI for generating OTP's mdp/rotp/pull/35

## 2.0.0

- Move to only comparing string OTP's.

## 1.7.0

- Move to only comparing string OTP's. See mdp/rotp/issues/32 - Moved to 2.0.0 - yanked from RubyGems

## 1.6.1

- Remove deprecation warning in Ruby 2.1.0 (@ylansegal)
- Add Ruby 2.0 and 2.1 to Travis

## 1.6.0

- Add verify_with_retries to HOTP
- Fix 'cgi' require and global DEFAULT_INTERVAL

## 1.5.0

- Add support for "issuer" parameter on provisioning url
- Add support for "period/interval" parameter on provisioning url

## 1.4.6

- Revert to previous Base32

## 1.4.5

- Fix and test correct implementation of Base32

## 1.4.4

- Fix issue with base32 decoding of strings in a length that's not a multiple of 8

## 1.4.3

- Bugfix on padding

## 1.4.2

- Better padding options (Pad the output with leading 0's)

## 1.4.1

- Clean up drift logic

## 1.4.0

- Added clock drift support via 'verify_with_drift' for TOTP

## 1.3.0

- Added support for Ruby 1.9.x
- Removed dependency on Base32
