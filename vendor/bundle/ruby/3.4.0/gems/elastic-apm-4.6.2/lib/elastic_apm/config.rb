# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# frozen_string_literal: true

require 'elastic_apm/config/bytes'
require 'elastic_apm/config/duration'
require 'elastic_apm/config/log_level_map'
require 'elastic_apm/config/options'
require 'elastic_apm/config/round_float'
require 'elastic_apm/config/regexp_list'
require 'elastic_apm/config/wildcard_pattern_list'
require 'elastic_apm/deprecations'
require 'elastic_apm/config/server_info'

module ElasticAPM
  # @api private
  class Config
    extend Options
    extend Deprecations

    SANITIZE_FIELD_NAMES_DEFAULT =
      %w[password passwd pwd secret *key *token* *session* *credit* *card* *auth* set-cookie].freeze

    # rubocop:disable Layout/LineLength, Layout/ExtraSpacing
    option :config_file,                       type: :string, default: 'config/elastic_apm.yml'
    option :server_url,                        type: :url,    default: 'http://localhost:8200'
    option :secret_token,                      type: :string
    option :api_key,                           type: :string

    option :api_buffer_size,                   type: :int,    default: 256
    option :api_request_size,                  type: :bytes,  default: '750kb', converter: Bytes.new
    option :api_request_time,                  type: :float,  default: '10s',   converter: Duration.new
    option :breakdown_metrics,                 type: :bool,   default: true
    option :capture_body,                      type: :string, default: 'off'
    option :capture_headers,                   type: :bool,   default: true
    option :capture_elasticsearch_queries,     type: :bool,   default: false
    option :capture_env,                       type: :bool,   default: true
    option :central_config,                    type: :bool,   default: true
    option :cloud_provider,                    type: :string, default: 'auto'
    option :current_user_email_method,         type: :string, default: 'email'
    option :current_user_id_method,            type: :string, default: 'id'
    option :current_user_username_method,      type: :string, default: 'username'
    option :custom_key_filters,                type: :list,   default: [],      converter: RegexpList.new
    option :default_labels,                    type: :dict,   default: {}
    option :disable_metrics,                   type: :list,   default: [],      converter: WildcardPatternList.new
    option :disable_send,                      type: :bool,   default: false
    option :disable_start_message,             type: :bool,   default: false
    option :disable_instrumentations,          type: :list,   default: %w[json]
    option :disabled_spies,                    type: :list,   default: []
    option :enabled,                           type: :bool,   default: true
    option :environment,                       type: :string, default: ENV['RAILS_ENV'] || ENV['RACK_ENV']
    option :framework_name,                    type: :string
    option :framework_version,                 type: :string
    option :filter_exception_types,            type: :list,   default: []
    option :global_labels,                     type: :dict
    option :hostname,                          type: :string
    option :http_compression,                  type: :bool,   default: true
    option :ignore_url_patterns,               type: :list,   default: [],      converter: RegexpList.new
    option :instrument,                        type: :bool,   default: true
    option :instrumented_rake_tasks,           type: :list,   default: []
    option :log_ecs_reformatting,              type: :string, default: 'off'
    option :log_level,                         type: :int,    default: Logger::INFO, converter: LogLevelMap.new
    option :log_path,                          type: :string
    option :metrics_interval,                  type: :int,    default: '30s',   converter: Duration.new
    option :pool_size,                         type: :int,    default: 1
    option :proxy_address,                     type: :string
    option :proxy_headers,                     type: :dict
    option :proxy_password,                    type: :string
    option :proxy_port,                        type: :int
    option :proxy_username,                    type: :string
    option :recording,                         type: :bool,   default: true
    option :sanitize_field_names,              type: :list,   default: SANITIZE_FIELD_NAMES_DEFAULT, converter: WildcardPatternList.new
    option :server_ca_cert_file,               type: :string
    option :service_name,                      type: :string
    option :service_node_name,                 type: :string
    option :service_version,                   type: :string
    option :source_lines_error_app_frames,     type: :int,    default: 5
    option :source_lines_error_library_frames, type: :int,    default: 0
    option :source_lines_span_app_frames,      type: :int,    default: 5
    option :source_lines_span_library_frames,  type: :int,    default: 0
    option :span_frames_min_duration,          type: :float,  default: '5ms',   converter: Duration.new(default_unit: 'ms')
    option :stack_trace_limit,                 type: :int,    default: 999_999
    option :transaction_ignore_urls,           type: :list,   default: [],      converter: WildcardPatternList.new
    option :transaction_max_spans,             type: :int,    default: 500
    option :transaction_sample_rate,           type: :float,  default: 1.0,     converter: RoundFloat.new
    option :use_elastic_traceparent_header,    type: :bool,   default: true
    option :verify_server_cert,                type: :bool,   default: true

    def log_ecs_formatting
      log_ecs_reformatting
    end

    def log_ecs_formatting=(value)
      @options[:log_ecs_reformatting].set(value)
    end

    deprecate :log_ecs_formatting, :log_ecs_reformatting

    # rubocop:enable Layout/LineLength, Layout/ExtraSpacing
    def initialize(options = {})
      @options = load_schema

      assign(options)

      # Pick out config_file specifically as we need it now to load it,
      # but still need the other env vars to have precedence
      env = load_env
      if (env_config_file = env.delete(:config_file))
        self.config_file = env_config_file
      end

      assign(load_config_file)
      assign(env)

      yield self if block_given?

      if self.logger.nil? || self.log_path
        self.logger = build_logger
      end

      @__view_paths ||= []
      @__root_path ||= Dir.pwd
    end

    attr_accessor :__view_paths, :__root_path, :logger

    attr_reader :options

    def assign(update)
      return unless update
      update.each { |key, value| send(:"#{key}=", value) }
    end

    def available_instrumentations
      %w[
        action_dispatch
        azure_storage_table
        delayed_job
        dynamo_db
        elasticsearch
        faraday
        http
        json
        mongo
        net_http
        rake
        racecar
        redis
        resque
        s3
        sequel
        shoryuken
        sidekiq
        sinatra
        sneakers
        sns
        sqs
        sucker_punch
        tilt
      ]
    end

    def enabled_instrumentations
      available_instrumentations - disable_instrumentations
    end

    def replace_options(new_options)
      return if new_options.nil? || new_options.empty?
      options_copy = @options.dup
      new_options.each do |key, value|
        options_copy.fetch(key.to_sym).set(value)
      end
      @options = options_copy
    end

    def app=(app)
      case app_type?(app)
      when :sinatra
        set_sinatra(app)
      when :rails
        set_rails(app)
      else
        self.service_name = 'ruby'
      end
    end

    def use_ssl?
      server_url.start_with?('https')
    end

    def collect_metrics?
      metrics_interval > 0
    end

    def span_frames_min_duration?
      span_frames_min_duration != 0
    end

    def span_frames_min_duration=(value)
      super
      @span_frames_min_duration_us = nil
    end

    def span_frames_min_duration_us
      @span_frames_min_duration_us ||= span_frames_min_duration * 1_000_000
    end

    def ssl_context
      return unless use_ssl?

      @ssl_context ||=
        OpenSSL::SSL::SSLContext.new.tap do |context|
          if server_ca_cert_file
            context.ca_file = server_ca_cert_file
          else
            context.cert_store =
              OpenSSL::X509::Store.new.tap(&:set_default_paths)
          end

          context.verify_mode =
            if verify_server_cert
              OpenSSL::SSL::VERIFY_PEER
            else
              OpenSSL::SSL::VERIFY_NONE
            end
        end
    end

    def inspect
      super.split.first + '>'
    end

    def version
      @version ||= ServerInfo.new(self).version
    end

    private

    def load_config_file
      return unless File.exist?(config_file)

      read = File.read(config_file)
      evaled = ERB.new(read).result
      YAML.safe_load(evaled)
    end

    def load_env
      @options.values.each_with_object({}) do |option, opts|
        next unless (value = ENV[option.env_key])
        opts[option.key] = value
      end
    end

    def build_logger
      if self.log_ecs_reformatting == 'override'
        begin
          return build_ecs_logger
        rescue LoadError
          logger.info "Attempted to use EcsLogging::Logger but the gem couldn't be " \
            "loaded so a ::Logger was created instead. Check if you have the `ecs-logging` " \
            "gem installed and attempt to start the agent again."
        end
      end

      Logger.new(log_path == '-' ? $stdout : log_path).tap do |logger|
        logger.level = log_level
      end
    end

    def build_ecs_logger
      require 'ecs_logging/logger'

      ::EcsLogging::Logger.new(log_path == '-' ? $stdout : log_path).tap do |logger|
        logger.level = log_level
      end
    end

    def app_type?(app)
      if defined?(::Rails::Application) && app.is_a?(::Rails::Application)
        return :rails
      end

      if app.is_a?(Class) && app.superclass.to_s == 'Sinatra::Base'
        return :sinatra
      end

      nil
    end

    def set_sinatra(app)
      self.service_name = format_name(service_name || app.to_s)
      self.framework_name = framework_name || 'Sinatra'
      self.framework_version = framework_version || ::Sinatra::VERSION
      self.__root_path = Dir.pwd
    end

    def set_rails(app)
      self.service_name ||= format_name(service_name || rails_app_name(app))
      self.framework_name ||= 'Ruby on Rails'
      self.framework_version ||= ::Rails::VERSION::STRING
      self.logger ||= ::Rails.logger
      self.log_level ||= ::Rails.logger.log_level

      self.__root_path = ::Rails.root.to_s
      self.__view_paths = app.config.paths['app/views'].existent +
                          [::Rails.root.to_s]
    end

    def rails_app_name(app)
      if ::Rails::VERSION::MAJOR >= 6
        app.class.module_parent_name
      else
        app.class.parent_name
      end
    end

    def format_name(str)
      str&.gsub('::', '_')
    end
  end
end
