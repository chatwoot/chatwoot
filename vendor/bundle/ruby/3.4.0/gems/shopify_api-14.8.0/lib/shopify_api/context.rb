# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  class Context
    extend T::Sig

    @api_key = T.let("", String)
    @api_secret_key = T.let("", String)
    @api_version = T.let(LATEST_SUPPORTED_ADMIN_VERSION, String)
    @api_host = T.let(nil, T.nilable(String))
    @scope = T.let(Auth::AuthScopes.new, Auth::AuthScopes)
    @is_private = T.let(false, T::Boolean)
    @private_shop = T.let(nil, T.nilable(String))
    @is_embedded = T.let(true, T::Boolean)
    # Logger can either be a Logger or an ActiveSupport::BroadcastLogger, which is new in Rails 7.1.0. To avoid adding a
    # dependency Active Support >= 7.1.0, we go with T.untyped
    @logger = T.let(::Logger.new($stdout), T.untyped)
    @log_level = T.let(:info, Symbol)
    @notified_missing_resources_folder = T.let({}, T::Hash[String, T::Boolean])
    @active_session = T.let(Concurrent::ThreadLocalVar.new { nil }, T.nilable(Concurrent::ThreadLocalVar))
    @user_agent_prefix = T.let(nil, T.nilable(String))
    @old_api_secret_key = T.let(nil, T.nilable(String))
    @response_as_struct = T.let(false, T.nilable(T::Boolean))
    @rest_disabled = T.let(false, T.nilable(T::Boolean))

    @rest_resource_loader = T.let(nil, T.nilable(Zeitwerk::Loader))

    class << self
      extend T::Sig

      sig do
        params(
          api_key: String,
          api_secret_key: String,
          api_version: String,
          is_private: T::Boolean,
          is_embedded: T::Boolean,
          scope: T.any(T::Array[String], String),
          log_level: T.any(String, Symbol),
          logger: T.untyped,
          host_name: T.nilable(String),
          host: T.nilable(String),
          private_shop: T.nilable(String),
          user_agent_prefix: T.nilable(String),
          old_api_secret_key: T.nilable(String),
          api_host: T.nilable(String),
          response_as_struct: T.nilable(T::Boolean),
          rest_disabled: T.nilable(T::Boolean),
        ).void
      end
      def setup(
        api_key:,
        api_secret_key:,
        api_version:,
        is_private:,
        is_embedded:,
        scope: [],
        log_level: :info,
        logger: ::Logger.new($stdout),
        host_name: nil,
        host: ENV["HOST"] || "https://#{host_name}",
        private_shop: nil,
        user_agent_prefix: nil,
        old_api_secret_key: nil,
        api_host: nil,
        response_as_struct: false,
        rest_disabled: false
      )
        unless ShopifyAPI::AdminVersions::SUPPORTED_ADMIN_VERSIONS.include?(api_version)
          raise Errors::UnsupportedVersionError,
            "Invalid version #{api_version}, supported versions: #{ShopifyAPI::AdminVersions::SUPPORTED_ADMIN_VERSIONS}"
        end

        @api_key = api_key
        @api_secret_key = api_secret_key
        @api_version = api_version
        @api_host = api_host
        @host = T.let(host, T.nilable(String))
        @is_private = is_private
        @scope = Auth::AuthScopes.new(scope)
        @is_embedded = is_embedded
        @logger = logger
        @private_shop = private_shop
        @user_agent_prefix = user_agent_prefix
        @old_api_secret_key = old_api_secret_key
        @response_as_struct = response_as_struct
        @rest_disabled = rest_disabled
        @log_level = if valid_log_level?(log_level)
          log_level.to_sym
        else
          :info
        end

        load_rest_resources(api_version: api_version)
      end

      sig { params(api_version: String).void }
      def load_rest_resources(api_version:)
        # Unload any previous instances - mostly useful for tests where we need to reset the version
        @rest_resource_loader&.setup
        @rest_resource_loader&.unload

        # No resources for the unstable version
        return if api_version == "unstable"

        version_folder_name = api_version.gsub("-", "_")
        path = "#{__dir__}/rest/resources/#{version_folder_name}"

        unless Dir.exist?(path)
          unless @notified_missing_resources_folder.key?(api_version)
            @logger.warn("Cannot autoload REST resources for API version '#{version_folder_name}', folder is missing")
            @notified_missing_resources_folder[api_version] = true
          end

          return
        end

        @rest_resource_loader = T.let(Zeitwerk::Loader.new, T.nilable(Zeitwerk::Loader))
        T.must(@rest_resource_loader).enable_reloading
        T.must(@rest_resource_loader).ignore("#{__dir__}/rest/resources")
        T.must(@rest_resource_loader).setup
        T.must(@rest_resource_loader).push_dir(path, namespace: ShopifyAPI)
        T.must(@rest_resource_loader).reload
      end

      sig { returns(String) }
      attr_reader :api_key, :api_secret_key, :api_version

      sig { returns(Auth::AuthScopes) }
      attr_reader :scope

      sig { returns(T.untyped) }
      attr_reader :logger

      sig { returns(Symbol) }
      attr_reader :log_level

      sig { returns T.nilable(T::Boolean) }
      attr_reader :response_as_struct

      sig { returns(T::Boolean) }
      def private?
        @is_private
      end

      sig { returns(T.nilable(String)) }
      attr_reader :private_shop, :user_agent_prefix, :old_api_secret_key, :host, :api_host

      sig { returns(T::Boolean) }
      def embedded?
        @is_embedded
      end

      sig { returns(T::Boolean) }
      def setup?
        [api_key, api_secret_key, T.must(host)].none?(&:empty?)
      end

      sig { returns(T.nilable(Auth::Session)) }
      def active_session
        @active_session&.value
      end

      sig { params(session: T.nilable(Auth::Session)).void }
      def activate_session(session)
        T.must(@active_session).value = session
      end

      sig { void }
      def deactivate_session
        T.must(@active_session).value = nil
      end

      sig { returns(String) }
      def host_scheme
        T.must(URI.parse(T.must(host)).scheme)
      end

      sig { returns(String) }
      def host_name
        T.must(URI(T.must(host)).host)
      end

      sig { returns(T::Boolean) }
      def rest_disabled
        T.must(@rest_disabled)
      end

      private

      sig { params(log_level: T.any(Symbol, String)).returns(T::Boolean) }
      def valid_log_level?(log_level)
        return true if ::ShopifyAPI::Logger.levels.include?(log_level.to_sym)

        ShopifyAPI::Logger.warn("#{log_level} is not a valid log_level. "\
          "Valid options are #{::ShopifyAPI::Logger.levels.join(", ")}")

        false
      end
    end
  end
end
