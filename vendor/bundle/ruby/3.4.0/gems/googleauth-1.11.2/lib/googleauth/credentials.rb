# Copyright 2017 Google, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "forwardable"
require "json"
require "signet/oauth_2/client"

require "googleauth/credentials_loader"

module Google
  module Auth
    ##
    # Credentials is a high-level base class used by Google's API client
    # libraries to represent the authentication when connecting to an API.
    # In most cases, it is subclassed by API-specific credential classes that
    # can be instantiated by clients.
    #
    # ## Options
    #
    # Credentials classes are configured with options that dictate default
    # values for parameters such as scope and audience. These defaults are
    # expressed as class attributes, and may differ from endpoint to endpoint.
    # Normally, an API client will provide subclasses specific to each
    # endpoint, configured with appropriate values.
    #
    # Note that these options inherit up the class hierarchy. If a particular
    # options is not set for a subclass, its superclass is queried.
    #
    # Some older users of this class set options via constants. This usage is
    # deprecated. For example, instead of setting the `AUDIENCE` constant on
    # your subclass, call the `audience=` method.
    #
    # ## Example
    #
    #     class MyCredentials < Google::Auth::Credentials
    #       # Set the default scope for these credentials
    #       self.scope = "http://example.com/my_scope"
    #     end
    #
    #     # creds is a credentials object suitable for Google API clients
    #     creds = MyCredentials.default
    #     creds.scope  # => ["http://example.com/my_scope"]
    #
    #     class SubCredentials < MyCredentials
    #       # Override the default scope for this subclass
    #       self.scope = "http://example.com/sub_scope"
    #     end
    #
    #     creds2 = SubCredentials.default
    #     creds2.scope  # => ["http://example.com/sub_scope"]
    #
    class Credentials # rubocop:disable Metrics/ClassLength
      ##
      # The default token credential URI to be used when none is provided during initialization.
      TOKEN_CREDENTIAL_URI = "https://oauth2.googleapis.com/token".freeze

      ##
      # The default target audience ID to be used when none is provided during initialization.
      AUDIENCE = "https://oauth2.googleapis.com/token".freeze

      @audience = @scope = @target_audience = @env_vars = @paths = @token_credential_uri = nil

      ##
      # The default token credential URI to be used when none is provided during initialization.
      # The URI is the authorization server's HTTP endpoint capable of issuing tokens and
      # refreshing expired tokens.
      #
      # @return [String]
      #
      def self.token_credential_uri
        lookup_auth_param :token_credential_uri do
          lookup_local_constant :TOKEN_CREDENTIAL_URI
        end
      end

      ##
      # Set the default token credential URI to be used when none is provided during initialization.
      #
      # @param [String] new_token_credential_uri
      #
      def self.token_credential_uri= new_token_credential_uri
        @token_credential_uri = new_token_credential_uri
      end

      ##
      # The default target audience ID to be used when none is provided during initialization.
      # Used only by the assertion grant type.
      #
      # @return [String]
      #
      def self.audience
        lookup_auth_param :audience do
          lookup_local_constant :AUDIENCE
        end
      end

      ##
      # Sets the default target audience ID to be used when none is provided during initialization.
      #
      # @param [String] new_audience
      #
      def self.audience= new_audience
        @audience = new_audience
      end

      ##
      # The default scope to be used when none is provided during initialization.
      # A scope is an access range defined by the authorization server.
      # The scope can be a single value or a list of values.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @return [String, Array<String>, nil]
      #
      def self.scope
        lookup_auth_param :scope do
          vals = lookup_local_constant :SCOPE
          vals ? Array(vals).flatten.uniq : nil
        end
      end

      ##
      # Sets the default scope to be used when none is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @param [String, Array<String>, nil] new_scope
      #
      def self.scope= new_scope
        new_scope = Array new_scope unless new_scope.nil?
        @scope = new_scope
      end

      ##
      # The default final target audience for ID tokens, to be used when none
      # is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @return [String, nil]
      #
      def self.target_audience
        lookup_auth_param :target_audience
      end

      ##
      # Sets the default final target audience for ID tokens, to be used when none
      # is provided during initialization.
      #
      # Either {#scope} or {#target_audience}, but not both, should be non-nil.
      # If {#scope} is set, this credential will produce access tokens.
      # If {#target_audience} is set, this credential will produce ID tokens.
      #
      # @param [String, nil] new_target_audience
      #
      def self.target_audience= new_target_audience
        @target_audience = new_target_audience
      end

      ##
      # The environment variables to search for credentials. Values can either be a file path to the
      # credentials file, or the JSON contents of the credentials file.
      # The env_vars will never be nil. If there are no vars, the empty array is returned.
      #
      # @return [Array<String>]
      #
      def self.env_vars
        env_vars_internal || []
      end

      ##
      # @private
      # Internal recursive lookup for env_vars.
      #
      def self.env_vars_internal
        lookup_auth_param :env_vars, :env_vars_internal do
          # Pull values when PATH_ENV_VARS or JSON_ENV_VARS constants exists.
          path_env_vars = lookup_local_constant :PATH_ENV_VARS
          json_env_vars = lookup_local_constant :JSON_ENV_VARS
          (Array(path_env_vars) + Array(json_env_vars)).flatten.uniq if path_env_vars || json_env_vars
        end
      end

      ##
      # Sets the environment variables to search for credentials.
      # Setting to `nil` "unsets" the value, and defaults to the superclass
      # (or to the empty array if there is no superclass).
      #
      # @param [String, Array<String>, nil] new_env_vars
      #
      def self.env_vars= new_env_vars
        new_env_vars = Array new_env_vars unless new_env_vars.nil?
        @env_vars = new_env_vars
      end

      ##
      # The file paths to search for credentials files.
      # The paths will never be nil. If there are no paths, the empty array is returned.
      #
      # @return [Array<String>]
      #
      def self.paths
        paths_internal || []
      end

      ##
      # @private
      # Internal recursive lookup for paths.
      #
      def self.paths_internal
        lookup_auth_param :paths, :paths_internal do
          # Pull in values if the DEFAULT_PATHS constant exists.
          vals = lookup_local_constant :DEFAULT_PATHS
          vals ? Array(vals).flatten.uniq : nil
        end
      end

      ##
      # Set the file paths to search for credentials files.
      # Setting to `nil` "unsets" the value, and defaults to the superclass
      # (or to the empty array if there is no superclass).
      #
      # @param [String, Array<String>, nil] new_paths
      #
      def self.paths= new_paths
        new_paths = Array new_paths unless new_paths.nil?
        @paths = new_paths
      end

      ##
      # @private
      # Return the given parameter value, defaulting up the class hierarchy.
      #
      # First returns the value of the instance variable, if set.
      # Next, calls the given block if provided. (This is generally used to
      # look up legacy constant-based values.)
      # Otherwise, calls the superclass method if present.
      # Returns nil if all steps fail.
      #
      # @param name [Symbol] The parameter name
      # @param method_name [Symbol] The lookup method name, if different
      # @return [Object] The value
      #
      def self.lookup_auth_param name, method_name = name
        val = instance_variable_get :"@#{name}"
        val = yield if val.nil? && block_given?
        return val unless val.nil?
        return superclass.send method_name if superclass.respond_to? method_name
        nil
      end

      ##
      # @private
      # Return the value of the given constant if it is defined directly in
      # this class, or nil if not.
      #
      # @param [Symbol] Name of the constant
      # @return [Object] The value
      #
      def self.lookup_local_constant name
        const_defined?(name, false) ? const_get(name) : nil
      end

      ##
      # The Signet::OAuth2::Client object the Credentials instance is using.
      #
      # @return [Signet::OAuth2::Client]
      #
      attr_accessor :client

      ##
      # Identifier for the project the client is authenticating with.
      #
      # @return [String]
      #
      attr_reader :project_id

      ##
      # Identifier for a separate project used for billing/quota, if any.
      #
      # @return [String,nil]
      #
      attr_reader :quota_project_id

      # @private Temporary; remove when universe domain metadata endpoint is stable (see b/349488459).
      def disable_universe_domain_check
        return false unless @client.respond_to? :disable_universe_domain_check
        @client.disable_universe_domain_check
      end

      # @private Delegate client methods to the client object.
      extend Forwardable

      ##
      # @!attribute [r] token_credential_uri
      #   @return [String] The token credential URI. The URI is the authorization server's HTTP
      #     endpoint capable of issuing tokens and refreshing expired tokens.
      #
      # @!attribute [r] audience
      #   @return [String] The target audience ID when issuing assertions. Used only by the
      #     assertion grant type.
      #
      # @!attribute [r] scope
      #   @return [String, Array<String>] The scope for this client. A scope is an access range
      #     defined by the authorization server. The scope can be a single value or a list of values.
      #
      # @!attribute [r] target_audience
      #   @return [String] The final target audience for ID tokens returned by this credential.
      #
      # @!attribute [r] issuer
      #   @return [String] The issuer ID associated with this client.
      #
      # @!attribute [r] signing_key
      #   @return [String, OpenSSL::PKey] The signing key associated with this client.
      #
      # @!attribute [r] updater_proc
      #   @return [Proc] Returns a reference to the {Signet::OAuth2::Client#apply} method,
      #     suitable for passing as a closure.
      #
      # @!attribute [rw] universe_domain
      #   @return [String] The universe domain issuing these credentials.
      #
      def_delegators :@client,
                     :token_credential_uri, :audience,
                     :scope, :issuer, :signing_key, :updater_proc, :target_audience,
                     :universe_domain, :universe_domain=

      ##
      # Creates a new Credentials instance with the provided auth credentials, and with the default
      # values configured on the class.
      #
      # @param [String, Hash, Signet::OAuth2::Client] keyfile
      #   The keyfile can be provided as one of the following:
      #
      #   * The path to a JSON keyfile (as a +String+)
      #   * The contents of a JSON keyfile (as a +Hash+)
      #   * A +Signet::OAuth2::Client+ object
      # @param [Hash] options
      #   The options for configuring the credentials instance. The following is supported:
      #
      #   * +:scope+ - the scope for the client
      #   * +"project_id"+ (and optionally +"project"+) - the project identifier for the client
      #   * +:connection_builder+ - the connection builder to use for the client
      #   * +:default_connection+ - the default connection to use for the client
      #
      def initialize keyfile, options = {}
        verify_keyfile_provided! keyfile
        options = symbolize_hash_keys options
        @project_id = options[:project_id] || options[:project]
        @quota_project_id = options[:quota_project_id]
        case keyfile
        when Google::Auth::BaseClient
          update_from_signet keyfile
        when Hash
          update_from_hash keyfile, options
        else
          update_from_filepath keyfile, options
        end
        @project_id ||= CredentialsLoader.load_gcloud_project_id
        @client.fetch_access_token! if @client.needs_access_token?
        @env_vars = nil
        @paths = nil
        @scope = nil
      end

      ##
      # Creates a new Credentials instance with auth credentials acquired by searching the
      # environment variables and paths configured on the class, and with the default values
      # configured on the class.
      #
      # The auth credentials are searched for in the following order:
      #
      # 1. configured environment variables (see {Credentials.env_vars})
      # 2. configured default file paths (see {Credentials.paths})
      # 3. application default (see {Google::Auth.get_application_default})
      #
      # @param [Hash] options
      #   The options for configuring the credentials instance. The following is supported:
      #
      #   * +:scope+ - the scope for the client
      #   * +"project_id"+ (and optionally +"project"+) - the project identifier for the client
      #   * +:connection_builder+ - the connection builder to use for the client
      #   * +:default_connection+ - the default connection to use for the client
      #
      # @return [Credentials]
      #
      def self.default options = {}
        # First try to find keyfile file or json from environment variables.
        client = from_env_vars options

        # Second try to find keyfile file from known file paths.
        client ||= from_default_paths options

        # Finally get instantiated client from Google::Auth
        client ||= from_application_default options
        client
      end

      ##
      # @private Lookup Credentials from environment variables.
      def self.from_env_vars options
        env_vars.each do |env_var|
          str = ENV[env_var]
          next if str.nil?
          io =
            if ::File.file? str
              ::StringIO.new ::File.read str
            else
              json = ::JSON.parse str rescue nil
              json ? ::StringIO.new(str) : nil
            end
          next if io.nil?
          return from_io io, options
        end
        nil
      end

      ##
      # @private Lookup Credentials from default file paths.
      def self.from_default_paths options
        paths.each do |path|
          next unless path && ::File.file?(path)
          io = ::StringIO.new ::File.read path
          return from_io io, options
        end
        nil
      end

      ##
      # @private Lookup Credentials using Google::Auth.get_application_default.
      def self.from_application_default options
        scope = options[:scope] || self.scope
        auth_opts = {
          token_credential_uri:   options[:token_credential_uri] || token_credential_uri,
          audience:               options[:audience] || audience,
          target_audience:        options[:target_audience] || target_audience,
          enable_self_signed_jwt: options[:enable_self_signed_jwt] && options[:scope].nil?
        }
        client = Google::Auth.get_application_default scope, auth_opts
        new client, options
      end

      # @private Read credentials from a JSON stream.
      def self.from_io io, options
        creds_input = {
          json_key_io:            io,
          scope:                  options[:scope] || scope,
          target_audience:        options[:target_audience] || target_audience,
          enable_self_signed_jwt: options[:enable_self_signed_jwt] && options[:scope].nil?,
          token_credential_uri:   options[:token_credential_uri] || token_credential_uri,
          audience:               options[:audience] || audience
        }
        client = Google::Auth::DefaultCredentials.make_creds creds_input
        new client
      end

      private_class_method :from_env_vars,
                           :from_default_paths,
                           :from_application_default,
                           :from_io

      protected

      # Verify that the keyfile argument is provided.
      def verify_keyfile_provided! keyfile
        return unless keyfile.nil?
        raise "The keyfile passed to Google::Auth::Credentials.new was nil."
      end

      # Verify that the keyfile argument is a file.
      def verify_keyfile_exists! keyfile
        exists = ::File.file? keyfile
        raise "The keyfile '#{keyfile}' is not a valid file." unless exists
      end

      # Initializes the Signet client.
      def init_client hash, options = {}
        options = update_client_options options
        io = StringIO.new JSON.generate hash
        options.merge! json_key_io: io
        Google::Auth::DefaultCredentials.make_creds options
      end

      # returns a new Hash with string keys instead of symbol keys.
      def stringify_hash_keys hash
        hash.to_h.transform_keys(&:to_s)
      end

      # returns a new Hash with symbol keys instead of string keys.
      def symbolize_hash_keys hash
        hash.to_h.transform_keys(&:to_sym)
      end

      def update_client_options options
        options = options.dup

        # options have higher priority over constructor defaults
        options[:token_credential_uri] ||= self.class.token_credential_uri
        options[:audience] ||= self.class.audience
        options[:scope] ||= self.class.scope
        options[:target_audience] ||= self.class.target_audience

        if !Array(options[:scope]).empty? && options[:target_audience]
          raise ArgumentError, "Cannot specify both scope and target_audience"
        end
        options.delete :scope unless options[:target_audience].nil?

        options
      end

      def update_from_signet client
        @project_id ||= client.project_id if client.respond_to? :project_id
        @quota_project_id ||= client.quota_project_id if client.respond_to? :quota_project_id
        @client = client
      end

      def update_from_hash hash, options
        hash = stringify_hash_keys hash
        hash["scope"] ||= options[:scope]
        hash["target_audience"] ||= options[:target_audience]
        @project_id ||= hash["project_id"] || hash["project"]
        @quota_project_id ||= hash["quota_project_id"]
        @client = init_client hash, options
      end

      def update_from_filepath path, options
        verify_keyfile_exists! path
        json = JSON.parse ::File.read(path)
        json["scope"] ||= options[:scope]
        json["target_audience"] ||= options[:target_audience]
        @project_id ||= json["project_id"] || json["project"]
        @quota_project_id ||= json["quota_project_id"]
        @client = init_client json, options
      end
    end
  end
end
