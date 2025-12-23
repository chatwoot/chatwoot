# CHANGELOG

## Unreleased

## 6.0.0

**Breaking Changes**
- `otp_secret_length` and `otp_backup_code_length` options have changed to be the number of random bytes that are generated. See [UPGRADING.md](UPGRADING.md).
- `consume_otp!` and `invalidate_otp_backup_code!` now call `save!` instead of `save`. See [UPGRADING.md](UPGRADING.md).

## 5.1.0

- Remove faker dev dependency
- Insert two_factor_authenticatable at the top of the devise module list
- README and CI improvements

## 5.0.0

**Breaking Changes**
- attr_encrypted has been deprecated in favor of native Rails attribute encryption. See [UPGRADING.md](UPGRADING.md) for details on how to migrate your records. You **must** use or build a migration strategy (see examples in [UPGRADING.md](UPGRADING.md)) to use existing data!
- Rails 7 is now required.

## 4.1.0 / 4.1.1
- Add support for attr_encrypted v4

## 4.0.2
- Add Rails 7.0 support
- Renew signing certificate
- Use `after` option of TOTP#verify for additional timestamp verification

## 4.0.1
- Convert CI from Travis CI to Github Actions ([#198](https://github.com/tinfoil/devise-two-factor/pull/198))
- Fix ActiveSupport::Testing::TimeHelpers require in shared examples ([#191](https://github.com/tinfoil/devise-two-factor/pull/191))
- Accept whitespace in provided codes ([#195](https://github.com/tinfoil/devise-two-factor/pull/195))
- Add Truffleruby head to CI ([#200](https://github.com/tinfoil/devise-two-factor/pull/200))

## 4.0.0
- [breaking] Drop support for Ruby <= 2.2
- Update ROTP
- Add Rails 6.1 support
- Remove timecop dependency
- Clarify changes in project ownership
- Bugfixes & cleanup

## 3.1.0
- Add Rails 6.0 support
- New gem signing certificate
- Fix paranoid-mode being ignored

## 3.0.3
- Add Rails 5.2 support

## 3.0.2
- Add Rails 5.1 support

## 3.0.1
- Qualify call to rspec shared_examples

## 3.0.0
See `UPGRADING.md` for specific help with breaking changes from 2.x to 3.0.0.

- Adds support for Devise 4.
- Relax dependencies to allow attr_encrypted 3.x.
- Blocks the use of attr_encrypted 2.x. There was a significant vulnerability in the encryption implementation in attr_encrypted 2.x, and that version of the gem should not be used.

## 2.2.0
- Use 192 bits, not 1024, as a secret key length. RFC 4226 recommends a minimum length of 128 bits and a recommended length of 160 bits. Google Authenticator doesn't accept 160 bit keys.

## 2.1.0
- Return false if OTP value is nil, instead of an ROTP exception.

## 2.0.1
No user-facing changes.

## 2.0.0
See `UPGRADING.md` for specific help with breaking changes from 1.x to 2.0.0.

- Replace `valid_otp?` method with `validate_and_consume_otp!`.
- Disallow subsequent OTPs once validated via timesteps.

## 1.1.0
- Removes runtimez activemodel dependency.
- Uses `Devise::Encryptor` instead of `Devise.bcrypt`, which is deprecated.
- Bump `rotp` dependency to 2.x.

## 1.0.2
- Makes Railties the only requirement for Rails generators.
- Explicitly check that the `otp_attempt` param is not nil in order to avoid 'ROTP only verifies strings' exceptions.
- Adding warning about recoverable devise strategy and automatic `sign_in` after a password reset.
- Loosen dependency version requirements for rotp, devise, and attr_encrypted.

## 1.0.1
- Add version requirements for dependencies.

## 1.0.0
- Initial release.
