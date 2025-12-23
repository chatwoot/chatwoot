# Upgrading

## Upgrading from 5.x to 6.x

### save!

`consume_otp!` and `invalidate_otp_backup_code!` now call `save!` instead of `save` (or nothing at all in the case of `invalidate_otp_backup_code!`). If you manually called `save`/`save!` after calling `invalidate_otp_backup_code!` you may be able to remove it.

### Secret Lengths

The `otp_secret_length` and `otp_backup_code_length` options have changed to be the number of random bytes that are generated.
If you had configured these values you may want to change them if you wish to keep the same output length.

`otp_secret_length` now has a default value of 20, generating a 160 bit secret key with an output length length of 32 bytes.

`otp_backup_code_length` now has a default value of 16, generating a 32 byte backup code.

## Upgrading from 4.x to 5.x

### Background

#### Database columns in version 4.x and older

Versions 4.x and older stored the OTP secret in an attribute called `encrypted_otp_secret` using the [attr_encrypted](https://github.com/attr-encrypted/attr_encrypted) gem. This gem is currently unmaintained which is part of the motivation for moving to Rails encrypted attributes. This attribute was backed by three database columns:

```
encrypted_otp_secret
encrypted_otp_secret_iv
encrypted_otp_secret_salt
```

Two other columns were also created:

```
consumed_timestep
otp_required_for_login
```

A fresh install of 4.x would create all five of the database columns above.

#### Database columns in version 5.x and later

Versions 5+ of this gem uses a single [Rails 7+ encrypted attribute](https://edgeguides.rubyonrails.org/active_record_encryption.html) named `otp_secret`to store the OTP secret in the database table (usually `users` but will be whatever model you picked).

A fresh install of 5+ will add the following columns to your `users` table:

```bash
otp_secret # this replaces encrypted_otp_secret, encrypted_otp_secret_iv, encrypted_otp_secret_salt
consumed_timestep
otp_required_for_login
```

We have attempted to make the upgrade as painless as possible but unfortunately because of the secret storage change, it cannot be as simple as `bundle update devise-two-factor` :heart:

### Assumptions

This guide assumes you are upgrading an existing Rails 6 app (with `devise` and `devise-two-factor`) to Rails 7.

This gem must be upgraded **as part of a Rails 7 upgrade**. See [the official Rails upgrading guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) for an overview of upgrading Rails.

### Phase 1: Upgrading devise-two-factor as part of Rails 7 upgrade

1. Update the version constraint for Rails in your `Gemfile` to your desired version e.g. `gem "rails", "~> 7.0.3"`
1. Run `bundle install` and resolve any issues with dependencies.
1. Update the version constraint for `devise-two-factor` in your `Gemfile` to the the latest version (must be at least 5.x e.g. `~> 5.0`
1. Run `./bin/rails app:update` as per the [Rails upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html) and tweak the output as required for your app.
1. Run `./bin/rails db:migrate` to update your DB based on the changes made by `app:update`
1. Add a new `otp_secret` attribute to your user model
    ```bash
    # TODO: replace 'User' in the migration name with the name of your user model
    ./bin/rails g migration AddOtpSecretToUser otp_secret:string
    ./bin/rails db:migrate
    ```
1. Add a `legacy_otp_secret` method to your user model e.g. `User`.
  * This method is used by the gem to find and decode the OTP secret from the legacy database columns.
  * The implementation shown below works if you set up devise-two-factor with the settings suggested in the [OLD README](https://github.com/devise-two-factor/devise-two-factor/blob/8d74f5ee45594bf00e60d5d49eb6fcde82c2d2ba/README.md).
  * If you have customised the encryption scheme used to store the OTP secret then you will need to update this method to match.
  * If you are unsure, you should try the method below as is, and if you can still sign in users with OTP enabled then all is well.
    ```ruby
    class User
      # ...

      private

      ##
      # Decrypt and return the `encrypted_otp_secret` attribute which was used in
      # prior versions of devise-two-factor
      # @return [String] The decrypted OTP secret
      def legacy_otp_secret
        return nil unless self[:encrypted_otp_secret]
        return nil unless self.class.otp_secret_encryption_key

        hmac_iterations = 2000 # a default set by the Encryptor gem
        key = self.class.otp_secret_encryption_key
        salt = Base64.decode64(encrypted_otp_secret_salt)
        iv = Base64.decode64(encrypted_otp_secret_iv)

        raw_cipher_text = Base64.decode64(encrypted_otp_secret)
        # The last 16 bytes of the ciphertext are the authentication tag - we use
        # Galois Counter Mode which is an authenticated encryption mode
        cipher_text = raw_cipher_text[0..-17]
        auth_tag =  raw_cipher_text[-16..-1]

        # this algorithm lifted from
        # https://github.com/attr-encrypted/encryptor/blob/master/lib/encryptor.rb#L54

        # create an OpenSSL object which will decrypt the AES cipher with 256 bit
        # keys in Galois Counter Mode (GCM). See
        # https://ruby.github.io/openssl/OpenSSL/Cipher.html
        cipher = OpenSSL::Cipher.new('aes-256-gcm')

        # tell the cipher we want to decrypt. Symmetric algorithms use a very
        # similar process for encryption and decryption, hence the same object can
        # do both.
        cipher.decrypt

        # Use a Password-Based Key Derivation Function to generate the key actually
        # used for encryption from the key we got as input.
        cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(key, salt, hmac_iterations, cipher.key_len)

        # set the Initialization Vector (IV)
        cipher.iv = iv

        # The tag must be set after calling Cipher#decrypt, Cipher#key= and
        # Cipher#iv=, but before calling Cipher#final. After all decryption is
        # performed, the tag is verified automatically in the call to Cipher#final.
        #
        # If the auth_tag does not verify, then #final will raise OpenSSL::Cipher::CipherError
        cipher.auth_tag = auth_tag

        # auth_data must be set after auth_tag has been set when decrypting See
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html#method-i-auth_data-3D
        # we are not adding any authenticated data but OpenSSL docs say this should
        # still be called.
        cipher.auth_data = ''

        # #update is (somewhat confusingly named) the method which actually
        # performs the decryption on the given chunk of data. Our OTP secret is
        # short so we only need to call it once.
        #
        # It is very important that we call #final because:
        #
        # 1. The authentication tag is checked during the call to #final
        # 2. Block based cipher modes (e.g. CBC) work on fixed size chunks. We need
        #    to call #final to get it to process the last chunk properly. The output
        #    of #final should be appended to the decrypted value. This isn't
        #    required for streaming cipher modes but including it is a best practice
        #    so that your code will continue to function correctly even if you later
        #    change to a block cipher mode.
        cipher.update(cipher_text) + cipher.final
      end
    end
    ```
2. Set up [Rails encrypted secrets](https://edgeguides.rubyonrails.org/active_record_encryption.html)
    ```bash
    ./bin/rails db:encryption:init
    # capture the output and put in encrypted credentials via
    ./bin/rails credentials:edit
    ```
3. Complete your Rails 7 upgrade (making whatever other changes are required)

You can now deploy your upgraded application and devise-two-factor should work as before.

This gem will fall back to **reading** the OTP secret from the legacy columns if it cannot find one in the new `otp_secret` column. When you **write** a new OTP secret it will always be written to the new `otp_secret` column.

### Phase 2: Clean up

This "clean up" phase can happen at the same time as your initial deployment but teams managing existing apps will likely want to do clean-up as separate, later deployments.

1. Create a rake task to copy the OTP secret for each user from the legacy column to the new `otp_secret` column. This prepares the way for us to remove the legacy columns in a later step.
    ```ruby
    # lib/tasks/devise_two_factor_migration.rake

    # Use this as a starting point for your task to migrate your user's OTP secrets.
    namespace :devise_two_factor do
      desc "Copy devise_two_factor OTP secret from old format to new format"
      task copy_otp_secret_to_rails7_encrypted_attr: [:environment] do
        # TODO: change User to your user model
        User.find_each do |user| # find_each finds in batches of 1,000 by default
          otp_secret = user.otp_secret # read from otp_secret column, fall back to legacy columns if new column is empty
          puts "Processing #{user.email}"
          user.update!(otp_secret: otp_secret)
        end
      end
    end
    ```
1. Remove the `#legacy_otp_secret` method from your user model (e.g. `User`) because it is no longer required.
1. Remove the now unused legacy columns from the database. This assumes you have run a rake task as in the previous step to migrate all the legacy stored secrets to the new storage.
    ```bash
    # TODO: replace 'Users' in migration name with the name of your user model
    ./bin/rails g migration RemoveLegacyDeviseTwoFactorSecretsFromUsers
    ```
    which generates
    ```ruby
    class RemoveLegacyDeviseTwoFactorSecretsFromUsers < ActiveRecord::Migration[7.0]
      def change
        # TODO: change :users to whatever your users table is

        # WARNING: Only run this when you are confident you have copied the OTP
        # secret for ALL users from `encrypted_otp_secret` to `otp_secret`!
        remove_column :users, :encrypted_otp_secret
        remove_column :users, :encrypted_otp_secret_iv
        remove_column :users, :encrypted_otp_secret_salt
      end
    end
    ```
1. Remove `otp_secret_encryption_key` from the model setup. This also assumes you successfully ran the rake task in step 1.
    ```ruby
    # from this:
    devise :two_factor_authenticatable,
        otp_secret_encryption_key: ENV['YOUR_ENCRYPTION_KEY_HERE']

    # to this:
    devise :two_factor_authenticatable
    ```

## Upgrading from 2.x to 3.x

Pull request #76 allows for compatibility with `attr_encrypted` 3.0, which should be used due to a security vulnerability discovered in 2.0.

Pull request #73 allows for compatibility with `attr_encrypted` 2.0. This version changes many of the defaults which must be taken into account to avoid corrupted OTP secrets on your model.

Due to new security practices in `attr_encrypted` an encryption key with insufficient length will cause an error. If you run into this, you may set `insecure_mode: true` in the `attr_encrypted` options.

You should initially add compatibility by specifying the `attr_encrypted` attribute in your model (`User` for these examples) with the old default encryption algorithm before invoking `devise :two_factor_authenticatable`:
```ruby
class User < ActiveRecord::Base
  attr_encrypted :otp_secret,
    :key       => self.otp_secret_encryption_key,
    :mode      => :per_attribute_iv_and_salt,
    :algorithm => 'aes-256-cbc'

  devise :two_factor_authenticatable,
         :otp_secret_encryption_key => ENV['DEVISE_TWO_FACTOR_ENCRYPTION_KEY']
```

## Upgrading from 1.x to 2.x

Pull request #43 added a new field to protect against "shoulder-surfing" attacks. If upgrading, you'll need to add the `:consumed_timestep` column to your `Users` model.

```ruby
class AddConsumedTimestepToUsers < ActiveRecord::Migration
  def change
    add_column :users, :consumed_timestep, :integer
  end
end
```

All uses of the `valid_otp?` method should be switched to `validate_and_consume_otp!`
