# frozen_string_literal: true

require 'forwardable'

module Aws
  module S3

    REQUIRED_PARAMS = [:key_wrap_schema, :content_encryption_schema, :security_profile]
    SUPPORTED_SECURITY_PROFILES = [:v2, :v2_and_legacy]

    # Provides an encryption client that encrypts and decrypts data client-side,
    # storing the encrypted data in Amazon S3.  The `EncryptionV2::Client` (V2 Client)
    # provides improved security over the `Encryption::Client` (V1 Client)
    # by using more modern and secure algorithms. You can use the V2 Client
    # to continue decrypting objects encrypted using deprecated algorithms
    # by setting security_profile: :v2_and_legacy. The latest V1 Client also
    # supports reading and decrypting objects encrypted by the V2 Client.
    #
    # This client uses a process called "envelope encryption". Your private
    # encryption keys and your data's plain-text are **never** sent to
    # Amazon S3. **If you lose you encryption keys, you will not be able to
    # decrypt your data.**
    #
    # ## Envelope Encryption Overview
    #
    # The goal of envelope encryption is to combine the performance of
    # fast symmetric encryption while maintaining the secure key management
    # that asymmetric keys provide.
    #
    # A one-time-use symmetric key (envelope key) is generated client-side.
    # This is used to encrypt the data client-side. This key is then
    # encrypted by your master key and stored alongside your data in Amazon
    # S3.
    #
    # When accessing your encrypted data with the encryption client,
    # the encrypted envelope key is retrieved and decrypted client-side
    # with your master key. The envelope key is then used to decrypt the
    # data client-side.
    #
    # One of the benefits of envelope encryption is that if your master key
    # is compromised, you have the option of just re-encrypting the stored
    # envelope symmetric keys, instead of re-encrypting all of the
    # data in your account.
    #
    # ## Basic Usage
    #
    # The encryption client requires an {Aws::S3::Client}. If you do not
    # provide a `:client`, then a client will be constructed for you.
    #
    #     require 'openssl'
    #     key = OpenSSL::PKey::RSA.new(1024)
    #
    #     # encryption client
    #     s3 = Aws::S3::EncryptionV2::Client.new(
    #       encryption_key: key,
    #       key_wrap_schema: :rsa_oaep_sha1, # the key_wrap_schema must be rsa_oaep_sha1 for asymmetric keys
    #       content_encryption_schema: :aes_gcm_no_padding,
    #       security_profile: :v2 # use :v2_and_legacy to allow reading/decrypting objects encrypted by the V1 encryption client
    #     )
    #
    #     # round-trip an object, encrypted/decrypted locally
    #     s3.put_object(bucket:'aws-sdk', key:'secret', body:'handshake')
    #     s3.get_object(bucket:'aws-sdk', key:'secret').body.read
    #     #=> 'handshake'
    #
    #     # reading encrypted object without the encryption client
    #     # results in the getting the cipher text
    #     Aws::S3::Client.new.get_object(bucket:'aws-sdk', key:'secret').body.read
    #     #=> "... cipher text ..."
    #
    # ## Required Configuration
    #
    # You must configure all of the following:
    #
    # * a key or key provider - See the Keys section below. The key provided determines
    #   the key wrapping schema(s) supported for both encryption and decryption.
    # * `key_wrap_schema` - The key wrapping schema. It must match the type of key configured.
    # * `content_encryption_schema` - The only supported value currently is `:aes_gcm_no_padding`.
    #    More options will be added in future releases.
    # * `security_profile` - Determines the support for reading objects written
    #    using older key wrap or content encryption schemas. If you need to read
    #    legacy objects encrypted by an existing V1 Client, then set this to `:v2_and_legacy`.
    #    Otherwise, set it to `:v2`
    #
    # ## Keys
    #
    # For client-side encryption to work, you must provide one of the following:
    #
    # * An encryption key
    # * A {KeyProvider}
    # * A KMS encryption key id
    #
    # Additionally, the key wrapping schema must agree with the type of the key:
    # * :aes_gcm: An AES encryption key or a key provider.
    # * :rsa_oaep_sha1: An RSA encryption key or key provider.
    # * :kms_context: A KMS encryption key id
    #
    # ### An Encryption Key
    #
    # You can pass a single encryption key. This is used as a master key
    # encrypting and decrypting all object keys.
    #
    #     key = OpenSSL::Cipher.new("AES-256-ECB").random_key # symmetric key - used with `key_wrap_schema: :aes_gcm`
    #     key = OpenSSL::PKey::RSA.new(1024) # asymmetric key pair - used with `key_wrap_schema: :rsa_oaep_sha1`
    #
    #     s3 = Aws::S3::EncryptionV2::Client.new(
    #       encryption_key: key,
    #       key_wrap_schema: :aes_gcm, # or :rsa_oaep_sha1 if using RSA
    #       content_encryption_schema: :aes_gcm_no_padding,
    #       security_profile: :v2
    #     )
    #
    # ### Key Provider
    #
    # Alternatively, you can use a {KeyProvider}. A key provider makes
    # it easy to work with multiple keys and simplifies key rotation.
    #
    # ### KMS Encryption Key Id
    #
    # If you pass the id of an AWS Key Management Service (KMS) key and
    # use :kms_content for the key_wrap_schema, then KMS will be used to
    # generate, encrypt and decrypt object keys.
    #
    #     # keep track of the kms key id
    #     kms = Aws::KMS::Client.new
    #     key_id = kms.create_key.key_metadata.key_id
    #
    #     Aws::S3::EncryptionV2::Client.new(
    #       kms_key_id: key_id,
    #       kms_client: kms,
    #       key_wrap_schema: :kms_context,
    #       content_encryption_schema: :aes_gcm_no_padding,
    #       security_profile: :v2
    #     )
    #
    # ## Custom Key Providers
    #
    # A {KeyProvider} is any object that responds to:
    #
    # * `#encryption_materials`
    # * `#key_for(materials_description)`
    #
    # Here is a trivial implementation of an in-memory key provider.
    # This is provided as a demonstration of the key provider interface,
    # and should not be used in production:
    #
    #     class KeyProvider
    #
    #       def initialize(default_key_name, keys)
    #         @keys = keys
    #         @encryption_materials = Aws::S3::EncryptionV2::Materials.new(
    #           key: @keys[default_key_name],
    #           description: JSON.dump(key: default_key_name),
    #         )
    #       end
    #
    #       attr_reader :encryption_materials
    #
    #       def key_for(matdesc)
    #         key_name = JSON.parse(matdesc)['key']
    #         if key = @keys[key_name]
    #           key
    #         else
    #           raise "encryption key not found for: #{matdesc.inspect}"
    #         end
    #       end
    #     end
    #
    # Given the above key provider, you can create an encryption client that
    # chooses the key to use based on the materials description stored with
    # the encrypted object. This makes it possible to use multiple keys
    # and simplifies key rotation.
    #
    #     # uses "new-key" for encrypting objects, uses either for decrypting
    #     keys = KeyProvider.new('new-key', {
    #       "old-key" => Base64.decode64("kM5UVbhE/4rtMZJfsadYEdm2vaKFsmV2f5+URSeUCV4="),
    #       "new-key" => Base64.decode64("w1WLio3agRWRTSJK/Ouh8NHoqRQ6fn5WbSXDTHjXMSo="),
    #     }),
    #
    #     # chooses the key based on the materials description stored
    #     # with the encrypted object
    #     s3 = Aws::S3::EncryptionV2::Client.new(
    #       key_provider: keys,
    #       key_wrap_schema: ...,
    #       content_encryption_schema: :aes_gcm_no_padding,
    #       security_profile: :v2
    #     )
    #
    # ## Materials Description
    #
    # A materials description is JSON document string that is stored
    # in the metadata (or instruction file) of an encrypted object.
    # The {DefaultKeyProvider} uses the empty JSON document `"{}"`.
    #
    # When building a key provider, you are free to store whatever
    # information you need to identify the master key that was used
    # to encrypt the object.
    #
    # ## Envelope Location
    #
    # By default, the encryption client store the encryption envelope
    # with the object, as metadata. You can choose to have the envelope
    # stored in a separate "instruction file". An instruction file
    # is an object, with the key of the encrypted object, suffixed with
    # `".instruction"`.
    #
    # Specify the `:envelope_location` option as `:instruction_file` to
    # use an instruction file for storing the envelope.
    #
    #     # default behavior
    #     s3 = Aws::S3::EncryptionV2::Client.new(
    #       key_provider: ...,
    #       envelope_location: :metadata,
    #     )
    #
    #     # store envelope in a separate object
    #     s3 = Aws::S3::EncryptionV2::Client.new(
    #       key_provider: ...,
    #       envelope_location: :instruction_file,
    #       instruction_file_suffix: '.instruction' # default
    #       key_wrap_schema: ...,
    #       content_encryption_schema: :aes_gcm_no_padding,
    #       security_profile: :v2
    #     )
    #
    # When using an instruction file, multiple requests are made when
    # putting and getting the object. **This may cause issues if you are
    # issuing concurrent PUT and GET requests to an encrypted object.**
    #
    module EncryptionV2
      class Client

        extend Deprecations
        extend Forwardable
        def_delegators :@client, :config, :delete_object, :head_object, :build_request

        # Creates a new encryption client. You must configure all of the following:
        #
        # * a key or key provider - The key provided also determines the key wrapping
        #   schema(s) supported for both encryption and decryption.
        # * `key_wrap_schema` - The key wrapping schema. It must match the type of key configured.
        # * `content_encryption_schema` - The only supported value currently is `:aes_gcm_no_padding`
        #    More options will be added in future releases.
        # * `security_profile` - Determines the support for reading objects written
        #    using older key wrap or content encryption schemas. If you need to read
        #    legacy objects encrypted by an existing V1 Client, then set this to `:v2_and_legacy`.
        #    Otherwise, set it to `:v2`
        #
        # To configure the key you must provide one of the following set of options:
        #
        # * `:encryption_key`
        # * `:kms_key_id`
        # * `:key_provider`
        #
        # You may also pass any other options accepted by `Client#initialize`.
        #
        # @option options [S3::Client] :client A basic S3 client that is used
        #   to make api calls. If a `:client` is not provided, a new {S3::Client}
        #   will be constructed.
        #
        # @option options [OpenSSL::PKey::RSA, String] :encryption_key The master
        #   key to use for encrypting/decrypting all objects.
        #
        # @option options [String] :kms_key_id When you provide a `:kms_key_id`,
        #   then AWS Key Management Service (KMS) will be used to manage the
        #   object encryption keys. By default a {KMS::Client} will be
        #   constructed for KMS API calls. Alternatively, you can provide
        #   your own via `:kms_client`. To only support decryption/reads, you may
        #   provide `:allow_decrypt_with_any_cmk` which will use
        #   the implicit CMK associated with the data during reads but will
        #   not allow you to encrypt/write objects with this client.
        #
        # @option options [#key_for] :key_provider Any object that responds
        #   to `#key_for`. This method should accept a materials description
        #   JSON document string and return return an encryption key.
        #
        # @option options [required, Symbol] :key_wrap_schema The Key wrapping
        #   schema to be used. It must match the type of key configured.
        #   Must be one of the following:
        #
        #   * :kms_context  (Must provide kms_key_id)
        #   * :aes_gcm (Must provide an AES (string) key)
        #   * :rsa_oaep_sha1 (Must provide an RSA key)
        #
        # @option options [required, Symbol] :content_encryption_schema
        #   Must be one of the following:
        #
        #   * :aes_gcm_no_padding
        #
        # @option options [Required, Symbol] :security_profile
        #   Determines the support for reading objects written using older
        #   key wrap or content encryption schemas.
        #   Must be one of the following:
        #
        #   * :v2 - Reads of legacy (v1) objects are NOT allowed
        #   * :v2_and_legacy - Enables reading of legacy (V1) schemas.
        #
        # @option options [Symbol] :envelope_location (:metadata) Where to
        #   store the envelope encryption keys. By default, the envelope is
        #   stored with the encrypted object. If you pass `:instruction_file`,
        #   then the envelope is stored in a separate object in Amazon S3.
        #
        # @option options [String] :instruction_file_suffix ('.instruction')
        #   When `:envelope_location` is `:instruction_file` then the
        #   instruction file uses the object key with this suffix appended.
        #
        # @option options [KMS::Client] :kms_client A default {KMS::Client}
        #   is constructed when using KMS to manage encryption keys.
        #
        def initialize(options = {})
          validate_params(options)
          @client = extract_client(options)
          @cipher_provider = cipher_provider(options)
          @envelope_location = extract_location(options)
          @instruction_file_suffix = extract_suffix(options)
          @kms_allow_decrypt_with_any_cmk =
            options[:kms_key_id] == :kms_allow_decrypt_with_any_cmk
          @security_profile = extract_security_profile(options)
        end

        # @return [S3::Client]
        attr_reader :client

        # @return [KeyProvider, nil] Returns `nil` if you are using
        #   AWS Key Management Service (KMS).
        attr_reader :key_provider

        # @return [Symbol] Determines the support for reading objects written
        #   using older key wrap or content encryption schemas.
        attr_reader :security_profile

        # @return [Boolean] If true the provided KMS key_id will not be used
        #   during decrypt, allowing decryption with the key_id from the object.
        attr_reader :kms_allow_decrypt_with_any_cmk

        # @return [Symbol<:metadata, :instruction_file>]
        attr_reader :envelope_location

        # @return [String] When {#envelope_location} is `:instruction_file`,
        #   the envelope is stored in the object with the object key suffixed
        #   by this string.
        attr_reader :instruction_file_suffix

        # Uploads an object to Amazon S3, encrypting data client-side.
        # See {S3::Client#put_object} for documentation on accepted
        # request parameters.
        # @option params [Hash] :kms_encryption_context Additional encryption
        #   context to use with KMS.  Applies only when KMS is used. In order
        #   to decrypt the object you will need to provide the identical
        #   :kms_encryption_context to `get_object`.
        # @option (see S3::Client#put_object)
        # @return (see S3::Client#put_object)
        # @see S3::Client#put_object
        def put_object(params = {})
          kms_encryption_context = params.delete(:kms_encryption_context)
          req = @client.build_request(:put_object, params)
          req.handlers.add(EncryptHandler, priority: 95)
          req.context[:encryption] = {
            cipher_provider: @cipher_provider,
            envelope_location: @envelope_location,
            instruction_file_suffix: @instruction_file_suffix,
            kms_encryption_context: kms_encryption_context
          }
          Aws::Plugins::UserAgent.feature('S3CryptoV2') do
            req.send_request
          end
        end

        # Gets an object from Amazon S3, decrypting data locally.
        # See {S3::Client#get_object} for documentation on accepted
        # request parameters.
        # Warning: If you provide a block to get_object or set the request
        # parameter :response_target to a Proc, then read the entire object to the
        # end before you start using the decrypted data. This is to verify that
        # the object has not been modified since it was encrypted.
        #
        # @option options [Symbol] :security_profile
        #   Determines the support for reading objects written using older
        #   key wrap or content encryption schemas. Overrides the value set
        #   on client construction if provided.
        #   Must be one of the following:
        #
        #   * :v2 - Reads of legacy (v1) objects are NOT allowed
        #   * :v2_and_legacy - Enables reading of legacy (V1) schemas.
        # @option params [String] :instruction_file_suffix The suffix
        #   used to find the instruction file containing the encryption
        #   envelope. You should not set this option when the envelope
        #   is stored in the object metadata. Defaults to
        #   {#instruction_file_suffix}.
        # @option params [Hash] :kms_encryption_context Additional encryption
        #   context to use with KMS.  Applies only when KMS is used.
        # @option options [Boolean] :kms_allow_decrypt_with_any_cmk (false)
        #   By default the KMS CMK ID (kms_key_id) will be used during decrypt
        #   and will fail if there is a mismatch.  Setting this to true
        #   will use the implicit CMK associated with the data.
        # @option (see S3::Client#get_object)
        # @return (see S3::Client#get_object)
        # @see S3::Client#get_object
        # @note The `:range` request parameter is not supported.
        def get_object(params = {}, &block)
          if params[:range]
            raise NotImplementedError, '#get_object with :range not supported'
          end
          envelope_location, instruction_file_suffix = envelope_options(params)
          kms_encryption_context = params.delete(:kms_encryption_context)
          kms_any_cmk_mode = kms_any_cmk_mode(params)
          security_profile = security_profile_from_params(params)

          req = @client.build_request(:get_object, params)
          req.handlers.add(DecryptHandler)
          req.context[:encryption] = {
            cipher_provider: @cipher_provider,
            envelope_location: envelope_location,
            instruction_file_suffix: instruction_file_suffix,
            kms_encryption_context: kms_encryption_context,
            kms_allow_decrypt_with_any_cmk: kms_any_cmk_mode,
            security_profile: security_profile
          }
          Aws::Plugins::UserAgent.feature('S3CryptoV2') do
            req.send_request(target: block)
          end
        end

        private

        # Validate required parameters exist and don't conflict.
        # The cek_alg and wrap_alg are passed on to the CipherProviders
        # and further validated there
        def validate_params(options)
          unless (missing_params = REQUIRED_PARAMS - options.keys).empty?
            raise ArgumentError, "Missing required parameter(s): "\
              "#{missing_params.map{ |s| ":#{s}" }.join(', ')}"
          end

          wrap_alg = options[:key_wrap_schema]

          # validate that the wrap alg matches the type of key given
          case wrap_alg
          when :kms_context
            unless options[:kms_key_id]
              raise ArgumentError, 'You must provide :kms_key_id to use :kms_context'
            end
          end
        end

        def extract_client(options)
          options[:client] || begin
            options = options.dup
            options.delete(:kms_key_id)
            options.delete(:kms_client)
            options.delete(:key_provider)
            options.delete(:encryption_key)
            options.delete(:envelope_location)
            options.delete(:instruction_file_suffix)
            REQUIRED_PARAMS.each { |p| options.delete(p) }
            S3::Client.new(options)
          end
        end

        def kms_client(options)
          options[:kms_client] || begin
            KMS::Client.new(
              region: @client.config.region,
              credentials: @client.config.credentials,
              )
          end
        end

        def cipher_provider(options)
          if options[:kms_key_id]
            KmsCipherProvider.new(
              kms_key_id: options[:kms_key_id],
              kms_client: kms_client(options),
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          else
            @key_provider = extract_key_provider(options)
            DefaultCipherProvider.new(
              key_provider: @key_provider,
              key_wrap_schema: options[:key_wrap_schema],
              content_encryption_schema: options[:content_encryption_schema]
            )
          end
        end

        def extract_key_provider(options)
          if options[:key_provider]
            options[:key_provider]
          elsif options[:encryption_key]
            DefaultKeyProvider.new(options)
          else
            msg = 'you must pass a :kms_key_id, :key_provider, or :encryption_key'
            raise ArgumentError, msg
          end
        end

        def envelope_options(params)
          location = params.delete(:envelope_location) || @envelope_location
          suffix = params.delete(:instruction_file_suffix)
          if suffix
            [:instruction_file, suffix]
          else
            [location, @instruction_file_suffix]
          end
        end

        def extract_location(options)
          location = options[:envelope_location] || :metadata
          if [:metadata, :instruction_file].include?(location)
            location
          else
            msg = ':envelope_location must be :metadata or :instruction_file '\
                  "got #{location.inspect}"
            raise ArgumentError, msg
          end
        end

        def extract_suffix(options)
          suffix = options[:instruction_file_suffix] || '.instruction'
          if suffix.is_a? String
            suffix
          else
            msg = ':instruction_file_suffix must be a String'
            raise ArgumentError, msg
          end
        end

        def kms_any_cmk_mode(params)
          if !params[:kms_allow_decrypt_with_any_cmk].nil?
            params.delete(:kms_allow_decrypt_with_any_cmk)
          else
            @kms_allow_decrypt_with_any_cmk
          end
        end

        def extract_security_profile(options)
          validate_security_profile(options[:security_profile])
        end

        def security_profile_from_params(params)
          security_profile =
            if !params[:security_profile].nil?
              params.delete(:security_profile)
            else
              @security_profile
            end
          validate_security_profile(security_profile)
        end

        def validate_security_profile(security_profile)
          unless SUPPORTED_SECURITY_PROFILES.include? security_profile
            raise ArgumentError, "Unsupported security profile: :#{security_profile}. " \
            "Please provide one of: #{SUPPORTED_SECURITY_PROFILES.map { |s| ":#{s}" }.join(', ')}"
          end
          if security_profile == :v2_and_legacy && !@warned_about_legacy
            @warned_about_legacy = true
            warn(
              'The S3 Encryption Client is configured to read encrypted objects ' \
              "with legacy encryption modes. If you don't have objects " \
              'encrypted with these legacy modes, you should disable support ' \
              'for them to enhance security.'
            )
          end
          security_profile
        end
      end
    end
  end
end
