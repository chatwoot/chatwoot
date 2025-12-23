module ScoutApm
  module ErrorService
    # Converts the raw error data captured into the captured data, and holds it
    # until it's ready to be reported.
    class ErrorRecord
      attr_reader :exception_class
      attr_reader :message
      attr_reader :request_uri
      attr_reader :request_params
      attr_reader :request_session
      attr_reader :environment
      attr_reader :trace
      attr_reader :request_components
      attr_reader :context

      def initialize(agent_context, exception, env, context=nil)
        @agent_context = agent_context

        @context = if context
          context.to_hash
        else
          {}
        end

        @exception_class = LengthLimit.new(exception.class.name).to_s
        @message = LengthLimit.new(exception.message, 100).to_s
        @request_uri = LengthLimit.new(rack_request_url(env), 200).to_s
        @request_params = clean_params(env["action_dispatch.request.parameters"])
        @request_session = clean_params(session_data(env))
        @environment = clean_params(strip_env(env))
        @trace = clean_backtrace(exception.backtrace)
        @request_components = components(env)
      end

      # TODO: This is rails specific
      def components(env)
        components = {}
        unless env["action_dispatch.request.parameters"].nil?
          components[:controller] = env["action_dispatch.request.parameters"][:controller] || nil
          components[:action] = env["action_dispatch.request.parameters"][:action] || nil
          components[:module] = env["action_dispatch.request.parameters"][:module] || nil
        end

        # For background workers like sidekiq
        # TODO: extract data creation for background jobs
        components[:controller] ||= env[:custom_controller]

        components
      end

      # TODO: Can I use the same thing we use in traces?
      def rack_request_url(env)
        protocol = rack_scheme(env)
        protocol = protocol.nil? ? "" : "#{protocol}://"

        host = env["SERVER_NAME"] || ""
        path = env["REQUEST_URI"] || ""
        port = env["SERVER_PORT"] || "80"
        port = ["80", "443"].include?(port.to_s) ? "" : ":#{port}"

        protocol.to_s + host.to_s + port.to_s + path.to_s
      end

      def rack_scheme(env)
        if env["HTTPS"] == "on"
          "https"
        elsif env["HTTP_X_FORWARDED_PROTO"]
          env["HTTP_X_FORWARDED_PROTO"].split(",")[0]
        else
          env["rack.url_scheme"]
        end
      end

      # TODO: This name is too vague
      def clean_params(params)
        return if params.nil?

        normalized = normalize_data(params)
        filter_params(normalized)
      end

      # TODO: When was backtrace_cleaner introduced?
      def clean_backtrace(backtrace)
        if defined?(Rails) && Rails.respond_to?(:backtrace_cleaner)
          Rails.backtrace_cleaner.send(:filter, backtrace)
        else
          backtrace
        end
      end

      # Deletes params from env
      #
      # These are not configurable, and will leak PII info up to Scout if
      # allowed through. Things like specific parameters can be exposed with
      # the ScoutApm::Context interface.
      KEYS_TO_REMOVE = [
        "rack.request.form_hash",
        "rack.request.form_vars",
        "async.callback",

        # Security related items
        "action_dispatch.secret_key_base",
        "action_dispatch.http_auth_salt",
        "action_dispatch.signed_cookie_salt",
        "action_dispatch.encrypted_cookie_salt",
        "action_dispatch.encrypted_signed_cookie_salt",
        "action_dispatch.authenticated_encrypted_cookie_salt",

        # Raw data from the URL & parameters. Would bypass our normal params filtering
        "QUERY_STRING",
        "REQUEST_URI",
        "REQUEST_PATH",
        "ORIGINAL_FULLPATH",
        "action_dispatch.request.query_parameters",
        "action_dispatch.request.parameters",
        "rack.request.query_string",
        "rack.request.query_hash",
      ]
      def strip_env(env)
        env.reject { |k, v| KEYS_TO_REMOVE.include?(k) }
      end

      def session_data(env)
        session = env["action_dispatch.request.session"]
        return if session.nil?

        if session.respond_to?(:to_hash)
          session.to_hash
        else
          session.data
        end
      end

      # TODO: Rename and make this clearer. I think it maps over the whole tree of a hash, and to_s each leaf node?
      def normalize_data(hash)
        new_hash = {}

        hash.each do |key, value|
          if value.respond_to?(:to_hash)
            begin
              new_hash[key] = normalize_data(value.to_hash)
            rescue
              new_hash[key] = LengthLimit.new(value.to_s).to_s
            end
          else
            new_hash[key] = LengthLimit.new(value.to_s).to_s
          end
        end

        new_hash
      end

      ###################
      # Filtering Params
      ###################

      # Replaces parameter values with a string / set in config file
      def filter_params(params)
        return params unless filtered_params_config

        params.each do |k, v|
          if filter_key?(k)
            params[k] = "[FILTERED]"
          elsif v.respond_to?(:to_hash)
            filter_params(params[k])
          end
        end

        params
      end

      # Check, if a key should be filtered
      def filter_key?(key)
        params_to_filter.any? do |filter|
          key.to_s == filter.to_s # key.to_s.include?(filter.to_s)
        end
      end

      def params_to_filter
        @params_to_filter ||= filtered_params_config + rails_filtered_params
      end

      # Accessor for the filtered params config value. Will be removed as we refactor and clean up this code.
      # TODO: Flip this over to use a new class like filtered exceptions?
      def filtered_params_config
        @agent_context.config.value("errors_filtered_params")
      end

      def rails_filtered_params
        return [] unless defined?(Rails)
        Rails.configuration.filter_parameters
      rescue 
        []
      end

      class LengthLimit
        attr_reader :text
        attr_reader :char_limit

        def initialize(text, char_limit=100)
          @text = text
          @char_limit = char_limit
        end

        def to_s
          text[0..char_limit]
        end
      end
    end
  end
end
