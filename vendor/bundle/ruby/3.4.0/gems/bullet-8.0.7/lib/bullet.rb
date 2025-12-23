# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/module/delegation'
require 'set'
require 'uniform_notifier'
require 'bullet/ext/object'
require 'bullet/ext/string'
require 'bullet/dependency'
require 'bullet/stack_trace_filter'

module Bullet
  extend Dependency

  autoload :ActiveRecord, "bullet/#{active_record_version}" if active_record?
  autoload :Mongoid, "bullet/#{mongoid_version}" if mongoid?
  autoload :Rack, 'bullet/rack'
  autoload :ActiveJob, 'bullet/active_job'
  autoload :Notification, 'bullet/notification'
  autoload :Detector, 'bullet/detector'
  autoload :Registry, 'bullet/registry'
  autoload :NotificationCollector, 'bullet/notification_collector'

  if defined?(Rails::Railtie)
    class BulletRailtie < Rails::Railtie
      initializer 'bullet.add_middleware' do |app|
        if defined?(ActionDispatch::ContentSecurityPolicy::Middleware) && Rails.application.config.content_security_policy && !app.config.api_only
          app.middleware.insert_before ActionDispatch::ContentSecurityPolicy::Middleware, Bullet::Rack
        else
          app.middleware.use Bullet::Rack
        end
      end
    end
  end

  class << self
    attr_writer :n_plus_one_query_enable,
                :unused_eager_loading_enable,
                :counter_cache_enable,
                :stacktrace_includes,
                :stacktrace_excludes,
                :skip_html_injection
    attr_reader :safelist
    attr_accessor :add_footer,
                  :orm_patches_applied,
                  :skip_http_headers,
                  :always_append_html_body,
                  :skip_user_in_notification

    available_notifiers =
      UniformNotifier::AVAILABLE_NOTIFIERS.select { |notifier| notifier != :raise }
                                          .map { |notifier| "#{notifier}=" }
    available_notifiers_options = { to: UniformNotifier }
    delegate(*available_notifiers, **available_notifiers_options)

    def raise=(should_raise)
      UniformNotifier.raise = (should_raise ? Notification::UnoptimizedQueryError : false)
    end

    DETECTORS = [
      Bullet::Detector::NPlusOneQuery,
      Bullet::Detector::UnusedEagerLoading,
      Bullet::Detector::CounterCache
    ].freeze

    def enable=(enable)
      @enable = enable

      if enable?
        reset_safelist
        unless orm_patches_applied
          self.orm_patches_applied = true
          Bullet::Mongoid.enable if mongoid?
          Bullet::ActiveRecord.enable if active_record?
        end
      end
    end

    alias enabled= enable=

    def enable?
      !!@enable
    end

    alias enabled? enable?

    # Rails.root might be nil if `railties` is a dependency on a project that does not use Rails
    def app_root
      @app_root ||= (defined?(::Rails.root) && !::Rails.root.nil? ? Rails.root.to_s : Dir.pwd).to_s
    end

    def n_plus_one_query_enable?
      enable? && (@n_plus_one_query_enable.nil? ? true : @n_plus_one_query_enable)
    end

    def unused_eager_loading_enable?
      enable? && (@unused_eager_loading_enable.nil? ? true : @unused_eager_loading_enable)
    end

    def counter_cache_enable?
      enable? && (@counter_cache_enable.nil? ? true : @counter_cache_enable)
    end

    def stacktrace_includes
      @stacktrace_includes ||= []
    end

    def stacktrace_excludes
      @stacktrace_excludes ||= []
    end

    def add_safelist(options)
      reset_safelist
      @safelist[options[:type]][options[:class_name]] ||= []
      @safelist[options[:type]][options[:class_name]] << options[:association].to_sym
    end

    def delete_safelist(options)
      reset_safelist
      @safelist[options[:type]][options[:class_name]] ||= []
      @safelist[options[:type]][options[:class_name]].delete(options[:association].to_sym)
      @safelist[options[:type]].delete_if { |_key, val| val.empty? }
    end

    def get_safelist_associations(type, class_name)
      Array.wrap(@safelist[type][class_name])
    end

    def reset_safelist
      @safelist ||= { n_plus_one_query: {}, unused_eager_loading: {}, counter_cache: {} }
    end

    def clear_safelist
      @safelist = nil
    end

    def bullet_logger=(active)
      if active
        require 'fileutils'
        FileUtils.mkdir_p(app_root + '/log')
        bullet_log_file = File.open("#{app_root}/log/bullet.log", 'a+')
        bullet_log_file.sync = true
        UniformNotifier.customized_logger = bullet_log_file
      end
    end

    def debug(title, message)
      puts "[Bullet][#{title}] #{message}" if ENV['BULLET_DEBUG'] == 'true'
    end

    def start_request
      Thread.current.thread_variable_set(:bullet_start, true)
      Thread.current.thread_variable_set(:bullet_notification_collector, Bullet::NotificationCollector.new)

      Thread.current.thread_variable_set(:bullet_object_associations, Bullet::Registry::Base.new)
      Thread.current.thread_variable_set(:bullet_call_object_associations, Bullet::Registry::Base.new)
      Thread.current.thread_variable_set(:bullet_possible_objects, Bullet::Registry::Object.new)
      Thread.current.thread_variable_set(:bullet_impossible_objects, Bullet::Registry::Object.new)
      Thread.current.thread_variable_set(:bullet_inversed_objects, Bullet::Registry::Base.new)
      Thread.current.thread_variable_set(:bullet_eager_loadings, Bullet::Registry::Association.new)
      Thread.current.thread_variable_set(:bullet_call_stacks, Bullet::Registry::CallStack.new)

      unless Thread.current.thread_variable_get(:bullet_counter_possible_objects)
        Thread.current.thread_variable_set(:bullet_counter_possible_objects, Bullet::Registry::Object.new)
      end

      unless Thread.current.thread_variable_get(:bullet_counter_impossible_objects)
        Thread.current.thread_variable_set(:bullet_counter_impossible_objects, Bullet::Registry::Object.new)
      end
    end

    def end_request
      Thread.current.thread_variable_set(:bullet_start, nil)
      Thread.current.thread_variable_set(:bullet_notification_collector, nil)

      Thread.current.thread_variable_set(:bullet_object_associations, nil)
      Thread.current.thread_variable_set(:bullet_call_object_associations, nil)
      Thread.current.thread_variable_set(:bullet_possible_objects, nil)
      Thread.current.thread_variable_set(:bullet_impossible_objects, nil)
      Thread.current.thread_variable_set(:bullet_inversed_objects, nil)
      Thread.current.thread_variable_set(:bullet_eager_loadings, nil)

      Thread.current.thread_variable_set(:bullet_counter_possible_objects, nil)
      Thread.current.thread_variable_set(:bullet_counter_impossible_objects, nil)
    end

    def start?
      enable? && Thread.current.thread_variable_get(:bullet_start)
    end

    def notification_collector
      Thread.current.thread_variable_get(:bullet_notification_collector)
    end

    def notification?
      return unless start?

      Bullet::Detector::UnusedEagerLoading.check_unused_preload_associations
      notification_collector.notifications_present?
    end

    def gather_inline_notifications
      responses = []
      for_each_active_notifier_with_notification { |notification| responses << notification.notify_inline }
      responses.join("\n")
    end

    def perform_out_of_channel_notifications(env = {})
      request_uri = build_request_uri(env)
      for_each_active_notifier_with_notification do |notification|
        notification.url = request_uri
        notification.notify_out_of_channel
      end
    end

    def footer_info
      info = []
      notification_collector.collection.each { |notification| info << notification.short_notice }
      info
    end

    def text_notifications
      info = []
      notification_collector.collection.each do |notification|
        info << notification.notification_data.values.compact.join("\n")
      end
      info
    end

    def warnings
      notification_collector.collection.each_with_object({}) do |notification, warnings|
        warning_type = notification.class.to_s.split(':').last.tableize
        warnings[warning_type] ||= []
        warnings[warning_type] << notification
      end
    end

    def profile
      return_value = nil

      if Bullet.enable?
        begin
          Bullet.start_request

          return_value = yield

          Bullet.perform_out_of_channel_notifications if Bullet.notification?
        ensure
          Bullet.end_request
        end
      else
        return_value = yield
      end

      return_value
    end

    def console_enabled?
      UniformNotifier.active_notifiers.include?(UniformNotifier::JavascriptConsole)
    end

    def inject_into_page?
      return false if defined?(@skip_html_injection) && @skip_html_injection

      console_enabled? || add_footer
    end

    private

    def for_each_active_notifier_with_notification
      UniformNotifier.active_notifiers.each do |notifier|
        notification_collector.collection.each do |notification|
          notification.notifier = notifier
          yield notification
        end
      end
    end

    def build_request_uri(env)
      return "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}" if env['REQUEST_URI']

      if env['QUERY_STRING'].present?
        "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}?#{env['QUERY_STRING']}"
      else
        "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
      end
    end
  end
end
