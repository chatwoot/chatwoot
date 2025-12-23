# Portions of this file are derived from AWS SDK for Ruby (Apache License 2.0)
# Modifications made by RubyLLM in 2025
# See THIRD_PARTY_LICENSES/AWS-SDK-NOTICE.txt for details

# frozen_string_literal: true

require 'openssl'
require 'tempfile'
require 'time'
require 'uri'
require 'set'
require 'cgi'
require 'pathname'

module RubyLLM
  module Providers
    class Bedrock
      module Signing
        # Utility class for creating AWS signature version 4 signature. This class
        # provides a method for generating signatures:
        #
        # * {#sign_request} - Computes a signature of the given request, returning
        #   the hash of headers that should be applied to the request.
        #
        # ## Configuration
        #
        # To use the signer, you need to specify the service, region, and credentials.
        # The service name is normally the endpoint prefix to an AWS service. For
        # example:
        #
        #     ec2.us-west-1.amazonaws.com => ec2
        #
        # The region is normally the second portion of the endpoint, following
        # the service name.
        #
        #     ec2.us-west-1.amazonaws.com => us-west-1
        #
        # It is important to have the correct service and region name, or the
        # signature will be invalid.
        #
        # ## Credentials
        #
        # The signer requires credentials. You can configure the signer
        # with static credentials:
        #
        #     signer = Aws::Sigv4::Signer.new(
        #       service: 's3',
        #       region: 'us-east-1',
        #       # static credentials
        #       access_key_id: 'akid',
        #       secret_access_key: 'secret'
        #     )
        #
        # You can also provide refreshing credentials via the `:credentials_provider`.
        # If you are using the AWS SDK for Ruby, you can use any of the credential
        # classes:
        #
        #     signer = Aws::Sigv4::Signer.new(
        #       service: 's3',
        #       region: 'us-east-1',
        #       credentials_provider: Aws::InstanceProfileCredentials.new
        #     )
        #
        # Other AWS SDK for Ruby classes that can be provided via `:credentials_provider`:
        #
        # * `Aws::Credentials`
        # * `Aws::SharedCredentials`
        # * `Aws::InstanceProfileCredentials`
        # * `Aws::AssumeRoleCredentials`
        # * `Aws::ECSCredentials`
        #
        # A credential provider is any object that responds to `#credentials`
        # returning another object that responds to `#access_key_id`, `#secret_access_key`,
        # and `#session_token`.
        module Errors
          # Error raised when AWS credentials are missing or incomplete
          class MissingCredentialsError < ArgumentError
            def initialize(msg = nil)
              super(msg || <<~MSG.strip)
                missing credentials, provide credentials with one of the following options:
                  - :access_key_id and :secret_access_key
                  - :credentials
                  - :credentials_provider
              MSG
            end
          end

          # Error raised when AWS region is not specified
          class MissingRegionError < ArgumentError
            def initialize(*_args)
              super('missing required option :region')
            end
          end
        end

        # Represents a signature for AWS request signing
        class Signature
          # @api private
          def initialize(options)
            options.each_pair do |attr_name, attr_value|
              send("#{attr_name}=", attr_value)
            end
          end

          # @return [Hash<String,String>] A hash of headers that should
          #   be applied to the HTTP request. Header keys are lower
          #   cased strings and may include the following:
          #
          #   * 'host'
          #   * 'x-amz-date'
          #   * 'x-amz-security-token'
          #   * 'x-amz-content-sha256'
          #   * 'authorization'
          #
          attr_accessor :headers

          # @return [String] For debugging purposes.
          attr_accessor :canonical_request

          # @return [String] For debugging purposes.
          attr_accessor :string_to_sign

          # @return [String] For debugging purposes.
          attr_accessor :content_sha256

          # @return [String] For debugging purposes.
          attr_accessor :signature

          # @return [Hash] Internal data for debugging purposes.
          attr_accessor :extra
        end

        # Manages AWS credentials for authentication
        class Credentials
          # @option options [required, String] :access_key_id
          # @option options [required, String] :secret_access_key
          # @option options [String, nil] :session_token (nil)
          def initialize(options = {})
            if options[:access_key_id] && options[:secret_access_key]
              @access_key_id = options[:access_key_id]
              @secret_access_key = options[:secret_access_key]
              @session_token = options[:session_token]
            else
              msg = 'expected both :access_key_id and :secret_access_key options'
              raise ArgumentError, msg
            end
          end

          # @return [String]
          attr_reader :access_key_id

          # @return [String]
          attr_reader :secret_access_key

          # @return [String, nil]
          attr_reader :session_token

          # @return [Boolean] Returns `true` if the access key id and secret
          #   access key are both set.
          def set?
            !access_key_id.nil? &&
              !access_key_id.empty? &&
              !secret_access_key.nil? &&
              !secret_access_key.empty?
          end
        end

        # Users that wish to configure static credentials can use the
        # `:access_key_id` and `:secret_access_key` constructor options.
        # @api private
        class StaticCredentialsProvider
          # @option options [Credentials] :credentials
          # @option options [String] :access_key_id
          # @option options [String] :secret_access_key
          # @option options [String] :session_token (nil)
          def initialize(options = {})
            @credentials = options[:credentials] || Credentials.new(options)
          end

          # @return [Credentials]
          attr_reader :credentials

          # @return [Boolean]
          def set?
            !!credentials && credentials.set?
          end
        end

        ParamComponent = Struct.new(:name, :value, :offset)

        # Utility methods for URI manipulation and hashing
        module UriUtils
          module_function

          def uri_escape_path(path)
            path.gsub(%r{[^/]+}) { |part| uri_escape(part) }
          end

          def uri_escape(string)
            if string.nil?
              nil
            else
              CGI.escape(string.encode('UTF-8')).gsub('+', '%20').gsub('%7E', '~')
            end
          end

          def normalize_path(uri)
            normalized_path = Pathname.new(uri.path).cleanpath.to_s
            # Pathname is probably not correct to use. Empty paths will
            # resolve to "." and should be disregarded
            normalized_path = '' if normalized_path == '.'
            # Ensure trailing slashes are correctly preserved
            normalized_path << '/' if uri.path.end_with?('/') && !normalized_path.end_with?('/')
            uri.path = normalized_path
          end

          def host(uri)
            # Handles known and unknown URI schemes; default_port nil when unknown.
            if uri.default_port == uri.port
              uri.host
            else
              "#{uri.host}:#{uri.port}"
            end
          end
        end

        # Cryptographic hash and digest utilities
        module CryptoUtils
          module_function

          # @param [String] value
          # @return [String<SHA256 Hexdigest>]
          def sha256_hexdigest(value)
            OpenSSL::Digest::SHA256.hexdigest(value)
          end

          def hmac(key, value)
            OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
          end

          def hexhmac(key, value)
            OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, value)
          end
        end

        # Configuration for canonical request creation
        class CanonicalRequestConfig
          attr_reader :uri_escape_path, :unsigned_headers

          def initialize(options = {})
            @uri_escape_path = options[:uri_escape_path] || true
            @unsigned_headers = options[:unsigned_headers] || Set.new
          end
        end

        # Handles canonical requests for AWS signature
        class CanonicalRequest
          # Builds a canonical request for AWS signature
          # @param [Hash] params Parameters for the canonical request
          def initialize(params = {})
            @http_method = params[:http_method]
            @url = params[:url]
            @headers = params[:headers]
            @content_sha256 = params[:content_sha256]
            @config = params[:config] || CanonicalRequestConfig.new
          end

          def to_s
            [
              @http_method,
              path,
              '', # Empty string instead of normalized_querystring since we don't use query params
              "#{canonical_headers}\n",
              signed_headers,
              @content_sha256
            ].join("\n")
          end

          # Returns the list of signed headers for authorization
          def signed_headers
            @headers.inject([]) do |signed_headers, (header, _)|
              if @config.unsigned_headers.include?(header)
                signed_headers
              else
                signed_headers << header
              end
            end.sort.join(';')
          end

          private

          def path
            path = @url.path
            path = '/' if path == ''
            if @config.uri_escape_path
              UriUtils.uri_escape_path(path)
            else
              path
            end
          end

          def canonical_headers
            headers = @headers.inject([]) do |hdrs, (k, v)|
              if @config.unsigned_headers.include?(k)
                hdrs
              else
                hdrs << [k, v]
              end
            end
            headers = headers.sort_by(&:first)
            headers.map { |k, v| "#{k}:#{canonical_header_value(v.to_s)}" }.join("\n")
          end

          def canonical_header_value(value)
            value.gsub(/\s+/, ' ').strip
          end
        end

        # Handles signature computation
        class SignatureComputation
          def initialize(service, region, signing_algorithm)
            @service = service
            @region = region
            @signing_algorithm = signing_algorithm
          end

          def string_to_sign(datetime, canonical_request, algorithm)
            [
              algorithm,
              datetime,
              credential_scope(datetime[0, 8]),
              CryptoUtils.sha256_hexdigest(canonical_request)
            ].join("\n")
          end

          def credential_scope(date)
            [
              date,
              @region,
              @service,
              'aws4_request'
            ].join('/')
          end

          def credential(credentials, date)
            "#{credentials.access_key_id}/#{credential_scope(date)}"
          end

          def signature(secret_access_key, date, string_to_sign)
            k_date = CryptoUtils.hmac("AWS4#{secret_access_key}", date)
            k_region = CryptoUtils.hmac(k_date, @region)
            k_service = CryptoUtils.hmac(k_region, @service)
            k_credentials = CryptoUtils.hmac(k_service, 'aws4_request')
            CryptoUtils.hexhmac(k_credentials, string_to_sign)
          end
        end

        # Extracts and validates request components
        class RequestExtractor
          # Extract and process request components
          # @param [Hash] request The request to process
          # @param [Hash] options Options for extraction
          # @return [Hash] Processed request components
          def self.extract_components(request, options = {})
            normalize_path = options.fetch(:normalize_path, true)

            # Extract base components
            http_method, url, headers = extract_base_components(request)
            UriUtils.normalize_path(url) if normalize_path

            # Process headers and compute content SHA256
            datetime = headers['x-amz-date'] || Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
            content_sha256 = extract_content_sha256(headers, request[:body])

            build_component_hash(http_method, url, headers, datetime, content_sha256)
          end

          def self.build_component_hash(http_method, url, headers, datetime, content_sha256)
            {
              http_method: http_method,
              url: url,
              headers: headers,
              datetime: datetime,
              date: datetime[0, 8],
              content_sha256: content_sha256
            }
          end

          def self.extract_base_components(request)
            http_method = extract_http_method(request)
            url = extract_url(request)
            headers = downcase_headers(request[:headers])
            [http_method, url, headers]
          end

          def self.extract_content_sha256(headers, body)
            headers['x-amz-content-sha256'] || CryptoUtils.sha256_hexdigest(body || '')
          end

          def self.extract_http_method(request)
            if request[:http_method]
              request[:http_method].upcase
            else
              msg = 'missing required option :http_method'
              raise ArgumentError, msg
            end
          end

          def self.extract_url(request)
            if request[:url]
              URI.parse(request[:url].to_s)
            else
              msg = 'missing required option :url'
              raise ArgumentError, msg
            end
          end

          def self.downcase_headers(headers)
            (headers || {}).to_hash.transform_keys(&:downcase)
          end
        end

        # Handles generating headers for AWS request signing
        class HeaderBuilder
          def initialize(options = {})
            @signing_algorithm = options[:signing_algorithm]
            @apply_checksum_header = options[:apply_checksum_header]
            @omit_session_token = options[:omit_session_token]
            @region = options[:region]
          end

          # Build headers for a signed request
          # @param [Hash] components Request components
          # @param [Credentials] creds AWS credentials
          # @return [Hash] Generated headers
          def build_sigv4_headers(components, creds)
            headers = {
              'host' => components[:headers]['host'] || UriUtils.host(components[:url]),
              'x-amz-date' => components[:datetime]
            }

            add_session_token_header(headers, creds)
            add_content_sha256_header(headers, components[:content_sha256])

            headers
          end

          # Build authorization headers for a signature
          # @param [Hash] sigv4_headers Headers for the signature
          # @param [Hash] signature The computed signature
          # @param [Hash] components Request components
          # @return [Hash] Headers with authorization
          def build_headers(sigv4_headers, signature, components)
            headers = sigv4_headers.merge(
              'authorization' => build_authorization_header(signature)
            )

            add_omitted_session_token(headers, components[:creds]) if @omit_session_token
            headers
          end

          def build_authorization_header(signature)
            [
              "#{signature[:algorithm]} Credential=#{signature[:credential]}",
              "SignedHeaders=#{signature[:signed_headers]}",
              "Signature=#{signature[:signature]}"
            ].join(', ')
          end

          private

          def add_session_token_header(headers, creds)
            return unless creds.session_token && !@omit_session_token

            headers['x-amz-security-token'] = creds.session_token
          end

          def add_content_sha256_header(headers, content_sha256)
            headers['x-amz-content-sha256'] = content_sha256 if @apply_checksum_header
          end

          def add_omitted_session_token(headers, creds)
            return unless creds&.session_token

            headers['x-amz-security-token'] = creds.session_token
          end
        end

        # Credential management and fetching
        class CredentialManager
          def initialize(credentials_provider)
            @credentials_provider = credentials_provider
          end

          def fetch_credentials
            credentials = @credentials_provider.credentials
            if credentials_set?(credentials)
              expiration = nil
              expiration = @credentials_provider.expiration if @credentials_provider.respond_to?(:expiration)
              [credentials, expiration]
            else
              raise Errors::MissingCredentialsError,
                    'unable to sign request without credentials set'
            end
          end

          def credentials_set?(credentials)
            !credentials.access_key_id.nil? &&
              !credentials.access_key_id.empty? &&
              !credentials.secret_access_key.nil? &&
              !credentials.secret_access_key.empty?
          end
        end

        # Result builder for signature computation
        class SignatureResultBuilder
          def initialize(signature_computation)
            @signature_computation = signature_computation
          end

          def build_result(request_data)
            result_hash(request_data)
          end

          private

          def result_hash(request_data)
            {
              algorithm: request_data[:algorithm],
              credential: credential_from_request(request_data),
              signed_headers: request_data[:canonical_request].signed_headers,
              signature: request_data[:signature],
              canonical_request: request_data[:creq],
              string_to_sign: request_data[:sts]
            }
          end

          def credential_from_request(request_data)
            @signature_computation.credential(
              request_data[:credentials],
              request_data[:date]
            )
          end
        end

        # Core functionality for computing signatures
        class SignatureGenerator
          def initialize(options = {})
            @signing_algorithm = :sigv4 # Always use sigv4
            @uri_escape_path = options[:uri_escape_path] || true
            @unsigned_headers = options[:unsigned_headers] || Set.new
            @service = options[:service]
            @region = options[:region]

            @signature_computation = SignatureComputation.new(@service, @region, @signing_algorithm)
            @result_builder = SignatureResultBuilder.new(@signature_computation)
          end

          def sts_algorithm
            'AWS4-HMAC-SHA256' # Always use HMAC-SHA256
          end

          def compute_signature(components, creds, sigv4_headers)
            algorithm = sts_algorithm
            headers = components[:headers].merge(sigv4_headers)

            # Process request and generate signature
            canonical_request = create_canonical_request(components, headers)
            sig = compute_signature_from_request(canonical_request, components, creds, algorithm)

            # Build and return the final result
            build_signature_result(components, creds, canonical_request, sig, algorithm)
          end

          private

          def compute_signature_from_request(canonical_request, components, creds, algorithm)
            creq = canonical_request.to_s
            sts = generate_string_to_sign(components, creq, algorithm)
            generate_signature(creds, components[:date], sts)
          end

          def generate_string_to_sign(components, creq, algorithm)
            @signature_computation.string_to_sign(
              components[:datetime],
              creq,
              algorithm
            )
          end

          def build_signature_result(components, creds, canonical_request, sig, algorithm)
            @result_builder.build_result(
              algorithm: algorithm,
              credentials: creds,
              date: components[:date],
              signature: sig,
              creq: canonical_request.to_s,
              sts: generate_string_to_sign(components, canonical_request.to_s, algorithm),
              canonical_request: canonical_request
            )
          end

          def create_canonical_request(components, headers)
            canon_req_config = create_canonical_request_config

            CanonicalRequest.new(
              http_method: components[:http_method],
              url: components[:url],
              headers: headers,
              content_sha256: components[:content_sha256],
              config: canon_req_config
            )
          end

          def create_canonical_request_config
            CanonicalRequestConfig.new(
              uri_escape_path: @uri_escape_path,
              unsigned_headers: @unsigned_headers
            )
          end

          def generate_signature(creds, date, string_to_sign)
            @signature_computation.signature(creds.secret_access_key, date, string_to_sign)
          end
        end

        # Utility for extracting options and config
        class SignerOptionExtractor
          def self.extract_service(options)
            if options[:service]
              options[:service]
            else
              msg = 'missing required option :service'
              raise ArgumentError, msg
            end
          end

          def self.extract_region(options)
            raise Errors::MissingRegionError unless options[:region]

            options[:region]
          end

          def self.extract_credentials_provider(options)
            if options[:credentials_provider]
              options[:credentials_provider]
            elsif options.key?(:credentials) || options.key?(:access_key_id)
              StaticCredentialsProvider.new(options)
            else
              raise Errors::MissingCredentialsError
            end
          end

          def self.initialize_unsigned_headers(options)
            headers = Set.new(options.fetch(:unsigned_headers, []).map(&:downcase))
            headers.merge(%w[authorization x-amzn-trace-id expect])
          end
        end

        # Handles initialization of Signer dependencies
        class SignerInitializer
          def self.create_components(options = {})
            service, region, credentials_provider = extract_core_components(options)
            unsigned_headers = SignerOptionExtractor.initialize_unsigned_headers(options)

            config_options = extract_config_options(options)

            components = {
              service: service,
              region: region,
              credentials_provider: credentials_provider,
              unsigned_headers: unsigned_headers
            }.merge(config_options)

            create_service_components(components)
          end

          def self.extract_core_components(options)
            service = SignerOptionExtractor.extract_service(options)
            region = SignerOptionExtractor.extract_region(options)
            credentials_provider = SignerOptionExtractor.extract_credentials_provider(options)

            [service, region, credentials_provider]
          end

          def self.extract_config_options(options)
            {
              uri_escape_path: options.fetch(:uri_escape_path, true),
              apply_checksum_header: options.fetch(:apply_checksum_header, true),
              normalize_path: options.fetch(:normalize_path, true),
              omit_session_token: options.fetch(:omit_session_token, false)
            }
          end

          def self.create_service_components(components)
            signature_generator = create_signature_generator(components)
            header_builder = create_header_builder(components)
            credential_manager = CredentialManager.new(components[:credentials_provider])

            components.merge(
              signature_generator: signature_generator,
              header_builder: header_builder,
              credential_manager: credential_manager
            )
          end

          def self.create_signature_generator(components)
            SignatureGenerator.new(
              signing_algorithm: components[:signing_algorithm],
              uri_escape_path: components[:uri_escape_path],
              unsigned_headers: components[:unsigned_headers],
              service: components[:service],
              region: components[:region]
            )
          end

          def self.create_header_builder(components)
            HeaderBuilder.new(
              signing_algorithm: components[:signing_algorithm],
              apply_checksum_header: components[:apply_checksum_header],
              omit_session_token: components[:omit_session_token],
              region: components[:region]
            )
          end
        end

        # Handles AWS request signing using SigV4 or SigV4a
        class Signer
          # Initialize a new signer with the provided options
          # @param [Hash] options Configuration options for the signer
          def initialize(options = {})
            components = SignerInitializer.create_components(options)
            setup_configuration(components)
            setup_service_components(components)
          end

          # @return [String]
          attr_reader :service

          # @return [String]
          attr_reader :region

          # @return [#credentials]
          attr_reader :credentials_provider

          # @return [Set<String>]
          attr_reader :unsigned_headers

          # @return [Boolean]
          attr_reader :apply_checksum_header

          # Sign an AWS request with SigV4 or SigV4a
          # @param [Hash] request The request to sign
          # @return [Signature] The signature with headers to apply
          def sign_request(request)
            creds = @credential_manager.fetch_credentials.first
            request_components = extract_request_components(request)
            sigv4_headers = build_sigv4_headers(request_components, creds)
            signature = compute_signature(request_components, creds, sigv4_headers)
            build_signature_response(request_components, sigv4_headers, signature)
          end

          private

          def setup_configuration(components)
            @service = components[:service]
            @region = components[:region]
            @credentials_provider = components[:credentials_provider]
            @unsigned_headers = components[:unsigned_headers]
            @uri_escape_path = components[:uri_escape_path]
            @apply_checksum_header = components[:apply_checksum_header]
            @signing_algorithm = components[:signing_algorithm]
            @normalize_path = components[:normalize_path]
            @omit_session_token = components[:omit_session_token]
          end

          def setup_service_components(components)
            @signature_generator = components[:signature_generator]
            @header_builder = components[:header_builder]
            @credential_manager = components[:credential_manager]
          end

          def extract_request_components(request)
            RequestExtractor.extract_components(
              request,
              normalize_path: @normalize_path
            )
          end

          def build_sigv4_headers(request_components, creds)
            @header_builder.build_sigv4_headers(request_components, creds)
          end

          def compute_signature(request_components, creds, sigv4_headers)
            @signature_generator.compute_signature(
              request_components,
              creds,
              sigv4_headers
            )
          end

          def build_signature_response(components, sigv4_headers, signature)
            headers = @header_builder.build_headers(sigv4_headers, signature, components)

            Signature.new(
              headers: headers,
              string_to_sign: signature[:string_to_sign],
              canonical_request: signature[:canonical_request],
              content_sha256: components[:content_sha256],
              signature: signature[:signature]
            )
          end

          class << self
            def uri_escape_path(path)
              UriUtils.uri_escape_path(path)
            end

            def uri_escape(string)
              UriUtils.uri_escape(string)
            end

            def normalize_path(uri)
              UriUtils.normalize_path(uri)
            end
          end
        end
      end
    end
  end
end
