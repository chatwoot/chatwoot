# frozen_string_literal: true

module Aws
  module Plugins
    # @api private
    class UserAgent < Seahorse::Client::Plugin
      # @api private
      option(:user_agent_suffix)
      # @api private
      option(:user_agent_frameworks, default: [])

      option(
        :sdk_ua_app_id,
        doc_type: 'String',
        docstring: <<-DOCS) do |cfg|
A unique and opaque application ID that is appended to the
User-Agent header as app/<sdk_ua_app_id>. It should have a
maximum length of 50.
        DOCS
        app_id = ENV['AWS_SDK_UA_APP_ID']
        app_id ||= Aws.shared_config.sdk_ua_app_id(profile: cfg.profile)
        app_id
      end

      def self.feature(feature, &block)
        Thread.current[:aws_sdk_core_user_agent_feature] ||= []
        Thread.current[:aws_sdk_core_user_agent_feature] << "ft/#{feature}"
        block.call
      ensure
        Thread.current[:aws_sdk_core_user_agent_feature].pop
      end

      # @api private
      class Handler < Seahorse::Client::Handler
        def call(context)
          set_user_agent(context)
          @handler.call(context)
        end

        def set_user_agent(context)
          context.http_request.headers['User-Agent'] = UserAgent.new(context).to_s
        end

        class UserAgent
          def initialize(context)
            @context = context
          end

          def to_s
            ua = "aws-sdk-ruby3/#{CORE_GEM_VERSION}"
            ua += ' ua/2.0'
            ua += " #{api_metadata}" if api_metadata
            ua += " #{os_metadata}"
            ua += " #{language_metadata}"
            ua += " #{env_metadata}" if env_metadata
            ua += " #{config_metadata}" if config_metadata
            ua += " #{app_id}" if app_id
            ua += " #{feature_metadata}" if feature_metadata
            ua += " #{framework_metadata}" if framework_metadata
            if @context.config.user_agent_suffix
              ua += " #{@context.config.user_agent_suffix}"
            end
            ua.strip
          end

          private

          # Used to be gem_name/gem_version
          def api_metadata
            service_id = @context.config.api.metadata['serviceId']
            return unless service_id

            service_id = service_id.gsub(' ', '_').downcase
            gem_version = @context[:gem_version]
            "api/#{service_id}##{gem_version}"
          end

          # Used to be RUBY_PLATFORM
          def os_metadata
            os =
              case RbConfig::CONFIG['host_os']
              when /mac|darwin/
                'macos'
              when /linux|cygwin/
                'linux'
              when /mingw|mswin/
                'windows'
              else
                'other'
              end
            metadata = "os/#{os}"
            local_version = Gem::Platform.local.version
            metadata += "##{local_version}" if local_version
            metadata += " md/#{RbConfig::CONFIG['host_cpu']}"
            metadata
          end

          # Used to be RUBY_ENGINE/RUBY_VERSION
          def language_metadata
            "lang/#{RUBY_ENGINE}##{RUBY_ENGINE_VERSION} md/#{RUBY_VERSION}"
          end

          def env_metadata
            return unless (execution_env = ENV['AWS_EXECUTION_ENV'])

            "exec-env/#{execution_env}"
          end

          def config_metadata
            "cfg/retry-mode##{@context.config.retry_mode}"
          end

          def app_id
            return unless (app_id = @context.config.sdk_ua_app_id)

            # Sanitize and only allow these characters
            app_id = app_id.gsub(/[^!#$%&'*+\-.^_`|~0-9A-Za-z]/, '-')
            "app/#{app_id}"
          end

          def feature_metadata
            return unless Thread.current[:aws_sdk_core_user_agent_feature]

            Thread.current[:aws_sdk_core_user_agent_feature].join(' ')
          end

          def framework_metadata
            if (frameworks_cfg = @context.config.user_agent_frameworks).empty?
              return
            end

            # Frameworks may be aws-record, aws-sdk-rails, etc.
            regex = /gems\/(?<name>#{frameworks_cfg.join('|')})-(?<version>\d+\.\d+\.\d+)/.freeze
            frameworks = {}
            Kernel.caller.each do |line|
              match = line.match(regex)
              next unless match

              frameworks[match[:name]] = match[:version]
            end
            frameworks.map { |n, v| "lib/#{n}##{v}" }.join(' ')
          end
        end
      end

      handler(Handler, priority: 1)
    end
  end
end
