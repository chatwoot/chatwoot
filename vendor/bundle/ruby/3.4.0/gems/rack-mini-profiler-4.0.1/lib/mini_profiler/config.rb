# frozen_string_literal: true

module Rack
  class MiniProfiler
    class Config
      def self.attr_accessor(*vars)
        @attributes ||= []
        @attributes.concat vars
        super(*vars)
      end

      def self.attributes
        @attributes
      end

      def self.default
        new.instance_eval {
          @auto_inject      = true # automatically inject on every html page
          @base_url_path    = "/mini-profiler-resources/".dup
          @cookie_path      = "/".dup
          @disable_caching  = true
          # called prior to rack chain, to ensure we are allowed to profile
          @pre_authorize_cb = lambda { |env| true }

          # called after rack chain, to ensure we are REALLY allowed to profile
          @skip_schema_queries    = false
          @storage                = MiniProfiler::MemoryStore
          @user_provider          = Proc.new { |env| Rack::Request.new(env).ip }
          @authorization_mode     = :allow_all
          @backtrace_threshold_ms = 0
          @flamegraph_sample_rate = 0.5
          @flamegraph_mode = :wall
          @flamegraph_ignore_gc = false
          @storage_failure = Proc.new do |exception|
            if @logger
              @logger.warn("MiniProfiler storage failure: #{exception.message}")
            end
          end
          @enabled = true
          @max_sql_param_length = 0 # disable sql parameter collection by default
          @skip_sql_param_names = /password/ # skips parameters with the name password by default
          @enable_advanced_debugging_tools = false
          @snapshot_every_n_requests = -1
          @max_snapshot_groups = 50
          @max_snapshots_per_group = 15

          # ui parameters
          @autorized            = true
          @collapse_results     = true
          @max_traces_to_show   = 20
          @show_children        = false
          @show_controls        = false
          @show_trivial         = false
          @show_total_sql_count = false
          @start_hidden         = false
          @toggle_shortcut      = 'alt+p'
          @html_container       = 'body'
          @position             = "top-left"
          @snapshot_hidden_custom_fields = []
          @snapshots_transport_destination_url = nil
          @snapshots_transport_auth_key = nil
          @snapshots_redact_sql_queries = true
          @snapshots_transport_gzip_requests = false
          @enable_hotwire_turbo_drive_support = false

          @profile_parameter = "pp"

          self
        }
      end

      attr_accessor :authorization_mode, :auto_inject, :backtrace_ignores,
        :backtrace_includes, :backtrace_remove, :backtrace_threshold_ms,
        :base_url_path, :cookie_path, :disable_caching, :enabled,
        :flamegraph_sample_rate, :logger, :pre_authorize_cb, :skip_paths,
        :skip_schema_queries, :storage, :storage_failure, :storage_instance,
        :storage_options, :user_provider, :enable_advanced_debugging_tools,
        :skip_sql_param_names, :suppress_encoding, :max_sql_param_length,
        :content_security_policy_nonce, :enable_hotwire_turbo_drive_support,
        :flamegraph_mode, :flamegraph_ignore_gc, :profile_parameter

      # ui accessors
      attr_accessor :collapse_results, :max_traces_to_show, :position,
        :show_children, :show_controls, :show_trivial, :show_total_sql_count,
        :start_hidden, :toggle_shortcut, :html_container

      # snapshot related config
      attr_accessor :snapshot_every_n_requests, :max_snapshots_per_group,
        :snapshot_hidden_custom_fields, :snapshots_transport_destination_url,
        :snapshots_transport_auth_key, :snapshots_redact_sql_queries,
        :snapshots_transport_gzip_requests, :max_snapshot_groups

      # Deprecated options
      attr_accessor :use_existing_jquery

      attr_reader :assets_url

      # redefined - since the accessor defines it first
      undef :authorization_mode=
      # rubocop:disable Lint/DuplicateMethods
      def authorization_mode=(mode)
        # rubocop:enable Lint/DuplicateMethods
        if mode == :whitelist
          warn "[DEPRECATION] `:whitelist` authorization mode is deprecated. Please use `:allow_authorized` instead."

          mode = :allow_authorized
        end

        warn <<~DEP unless mode == :allow_authorized || mode == :allow_all
          [DEPRECATION] unknown authorization mode #{mode}. Expected `:allow_all` or `:allow_authorized`.
        DEP

        @authorization_mode = mode
      end

      def assets_url=(lmbda)
        if defined?(Rack::MiniProfilerRails)
          Rack::MiniProfilerRails.create_engine
        end
        @assets_url = lmbda
      end

      def vertical_position
        position.include?('bottom') ? 'bottom' : 'top'
      end

      def horizontal_position
        position.include?('right') ? 'right' : 'left'
      end

      def merge!(config)
        if config
          if Hash === config
            config.each { |k, v| instance_variable_set "@#{k}", v }
          else
            self.class.attributes.each { |k|
              v = config.send k
              instance_variable_set "@#{k}", v if v
            }
          end
        end
      end

    end
  end
end
