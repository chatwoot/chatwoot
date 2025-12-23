# frozen_string_literal: true

require 'fileutils'
require_relative './railtie_methods'

module Rack::MiniProfilerRails
  extend Rack::MiniProfilerRailsMethods

  # call direct if needed to do a defer init
  def self.initialize!(app)

    raise "MiniProfilerRails initialized twice. Set `require: false' for rack-mini-profiler in your Gemfile" if defined?(@already_initialized) && @already_initialized

    c = Rack::MiniProfiler.config

    # By default, only show the MiniProfiler in development mode.
    # To use the MiniProfiler in production, call Rack::MiniProfiler.authorize_request
    # from a hook in your ApplicationController
    #
    # Example:
    #   before_action { Rack::MiniProfiler.authorize_request if current_user.is_admin? }
    #
    # NOTE: this must be set here with = and not ||=
    #  The out of the box default is "true"
    c.pre_authorize_cb = lambda { |env|
      !Rails.env.test?
    }

    c.skip_paths ||= []

    if serves_static_assets?(app)
      c.skip_paths << app.config.assets.prefix
      wp_assets_path = get_webpacker_assets_path()
      c.skip_paths << wp_assets_path if wp_assets_path
    end

    unless Rails.env.development? || Rails.env.test?
      c.authorization_mode = :allow_authorized
    end

    if Rails.logger
      c.logger = Rails.logger
    end

    # The file store is just so much less flaky
    # If the user has not changed from the default memory store then switch to the file store, otherwise keep what the user set
    if c.storage == Rack::MiniProfiler::MemoryStore && c.storage_options.nil?
      base_path = Rails.application.config.paths['tmp'].first rescue "#{Rails.root}/tmp"
      tmp       = base_path + '/miniprofiler'

      c.storage_options = { path: tmp }
      c.storage = Rack::MiniProfiler::FileStore
    end

    # Quiet the SQL stack traces
    c.backtrace_remove = Rails.root.to_s + "/"
    c.backtrace_includes =  [/^\/?(app|config|lib|test)/]
    c.skip_schema_queries = (Rails.env.development? || Rails.env.test?)

    # Install the Middleware
    app.middleware.insert(0, Rack::MiniProfiler)
    c.enable_advanced_debugging_tools = Rails.env.development?

    if ::Rack::MiniProfiler.patch_rails?
      # Attach to various Rails methods
      ActiveSupport.on_load(:action_controller) do
        ::Rack::MiniProfiler.profile_method(ActionController::Base, :process) { |action| "Executing action: #{action}" }
      end

      ActiveSupport.on_load(:action_view) do
        ::Rack::MiniProfiler.profile_method(ActionView::Template, :render) { |x, y| "Rendering: #{@virtual_path}" }
      end
    else
      subscribe("start_processing.action_controller") do |name, start, finish, id, payload|
        next if !should_measure?

        current = Rack::MiniProfiler.current
        controller_name = payload[:controller].sub(/Controller\z/, '').downcase
        description = "Executing: #{controller_name}##{payload[:action]}"
        Thread.current[get_key(payload)] = current.current_timer
        Rack::MiniProfiler.current.current_timer = current.current_timer.add_child(description)
      end

      subscribe("process_action.action_controller") do |name, start, finish, id, payload|
        next if !should_measure?

        key = get_key(payload)
        parent_timer = Thread.current[key]
        next if !parent_timer

        Thread.current[key] = nil
        Rack::MiniProfiler.current.current_timer.record_time
        Rack::MiniProfiler.current.current_timer = parent_timer
      end

      subscribe("render_partial.action_view") do |name, start, finish, id, payload|
        render_notification_handler(shorten_identifier(payload[:identifier]), finish, start)
      end

      subscribe("render_template.action_view") do |name, start, finish, id, payload|
        render_notification_handler(shorten_identifier(payload[:identifier]), finish, start)
      end

      if Rack::MiniProfiler.subscribe_sql_active_record
        # we don't want to subscribe if we've already patched a DB driver
        # otherwise we would end up with 2 records for every query
        subscribe("sql.active_record") do |name, start, finish, id, payload|
          next if !should_measure?
          next if payload[:name] =~ /SCHEMA/ && Rack::MiniProfiler.config.skip_schema_queries

          Rack::MiniProfiler.record_sql(
            payload[:sql],
            (finish - start) * 1000,
            Rack::MiniProfiler.binds_to_params(payload[:binds])
          )
        end

        subscribe("instantiation.active_record") do |name, start, finish, id, payload|
          next if !should_measure?

          Rack::MiniProfiler.report_reader_duration(
            (finish - start) * 1000,
            payload[:record_count],
            payload[:class_name]
          )
        end
      end
    end
    @already_initialized = true
  end

  def self.create_engine
    return if defined?(Rack::MiniProfilerRails::Engine)
    klass = Class.new(::Rails::Engine) do
      engine_name 'rack-mini-profiler'
      config.assets.paths << File.expand_path('../../html', __FILE__)
      config.assets.precompile << 'rack-mini-profiler.js'
      config.assets.precompile << 'rack-mini-profiler.css'
    end
    Rack::MiniProfilerRails.const_set("Engine", klass)
  end

  def self.subscribe(event, &blk)
    if ActiveSupport::Notifications.respond_to?(:monotonic_subscribe)
      ActiveSupport::Notifications.monotonic_subscribe(event) { |*args| blk.call(*args) }
    else
      ActiveSupport::Notifications.subscribe(event) do |name, start, finish, id, payload|
        blk.call(name, start.to_f, finish.to_f, id, payload)
      end
    end
  end

  def self.get_key(payload)
    "mini_profiler_parent_timer_#{payload[:controller]}_#{payload[:action]}".to_sym
  end

  def self.shorten_identifier(identifier)
    identifier.split('/').last(2).join('/')
  end

  def self.serves_static_assets?(app)
    config = app.config

    if !config.respond_to?(:assets) || !config.assets.respond_to?(:prefix)
      return false
    end

    if ::Rails.version >= "5.0.0"
      ::Rails.configuration.public_file_server.enabled
    elsif ::Rails.version >= "4.2.0"
      ::Rails.configuration.serve_static_files
    else
      ::Rails.configuration.serve_static_assets
    end
  end

  class Railtie < ::Rails::Railtie

    initializer "rack_mini_profiler.configure_rails_initialization" do |app|
      Rack::MiniProfilerRails.initialize!(app)
    end

    # Suppress compression when Rack::Deflater is lower in the middleware
    # stack than Rack::MiniProfiler
    config.after_initialize do |app|
      middlewares = app.middleware.middlewares
      if Rack::MiniProfiler.config.suppress_encoding.nil? &&
          middlewares.include?(Rack::Deflater) &&
          middlewares.include?(Rack::MiniProfiler) &&
          middlewares.index(Rack::Deflater) > middlewares.index(Rack::MiniProfiler)
        Rack::MiniProfiler.config.suppress_encoding = true
      end
    end

    # TODO: Implement something better here
    # config.after_initialize do
    #
    #   class ::ActionView::Helpers::AssetTagHelper::JavascriptIncludeTag
    #     alias_method :asset_tag_orig, :asset_tag
    #     def asset_tag(source,options)
    #       current = Rack::MiniProfiler.current
    #       return asset_tag_orig(source,options) unless current
    #       wrapped = ""
    #       unless current.mpt_init
    #         current.mpt_init = true
    #         wrapped << Rack::MiniProfiler::ClientTimerStruct.init_instrumentation
    #       end
    #       name = source.split('/')[-1]
    #       wrapped << Rack::MiniProfiler::ClientTimerStruct.instrument(name, asset_tag_orig(source,options)).html_safe
    #       wrapped
    #     end
    #   end

    #   class ::ActionView::Helpers::AssetTagHelper::StylesheetIncludeTag
    #     alias_method :asset_tag_orig, :asset_tag
    #     def asset_tag(source,options)
    #       current = Rack::MiniProfiler.current
    #       return asset_tag_orig(source,options) unless current
    #       wrapped = ""
    #       unless current.mpt_init
    #         current.mpt_init = true
    #         wrapped << Rack::MiniProfiler::ClientTimerStruct.init_instrumentation
    #       end
    #       name = source.split('/')[-1]
    #       wrapped << Rack::MiniProfiler::ClientTimerStruct.instrument(name, asset_tag_orig(source,options)).html_safe
    #       wrapped
    #     end
    #   end

    # end

  end
end
