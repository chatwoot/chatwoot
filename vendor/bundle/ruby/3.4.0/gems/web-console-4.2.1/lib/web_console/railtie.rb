# frozen_string_literal: true

require "rails/railtie"

module WebConsole
  class Railtie < ::Rails::Railtie
    config.web_console = ActiveSupport::OrderedOptions.new

    initializer "web_console.initialize" do
      require "bindex"
      require "web_console/extensions"

      ActionDispatch::DebugExceptions.register_interceptor(Interceptor)
    end

    initializer "web_console.development_only" do
      unless (config.web_console.development_only == false) || Rails.env.development?
        abort <<-END.strip_heredoc
          Web Console is activated in the #{Rails.env} environment. This is
          usually a mistake. To ensure it's only activated in development
          mode, move it to the development group of your Gemfile:

              gem 'web-console', group: :development

          If you still want to run it in the #{Rails.env} environment (and know
          what you are doing), put this in your Rails application
          configuration:

              config.web_console.development_only = false
        END
      end
    end

    initializer "web_console.insert_middleware" do |app|
      app.middleware.insert_before ActionDispatch::DebugExceptions, Middleware
    end

    initializer "web_console.mount_point" do
      if mount_point = config.web_console.mount_point
        Middleware.mount_point = mount_point.chomp("/")
      end

      if root = Rails.application.config.relative_url_root
        Middleware.mount_point = File.join(root, Middleware.mount_point)
      end
    end

    initializer "web_console.template_paths" do
      if template_paths = config.web_console.template_paths
        Template.template_paths.unshift(*Array(template_paths))
      end
    end

    initializer "web_console.deprecator" do |app|
      app.deprecators[:web_console] = WebConsole.deprecator if app.respond_to?(:deprecators)
    end

    initializer "web_console.permissions" do
      permissions = web_console_permissions
      Request.permissions = Permissions.new(permissions)
    end

    def web_console_permissions
      case
      when config.web_console.permissions
        config.web_console.permissions
      when config.web_console.allowed_ips
        config.web_console.allowed_ips
      when config.web_console.whitelisted_ips
        WebConsole.deprecator.warn(<<-MSG.squish)
          The config.web_console.whitelisted_ips is deprecated and will be ignored in future release of web_console.
          Please use config.web_console.allowed_ips instead.
        MSG
        config.web_console.whitelisted_ips
      end
    end

    initializer "web_console.whiny_requests" do
      if config.web_console.key?(:whiny_requests)
        Middleware.whiny_requests = config.web_console.whiny_requests
      end
    end

    initializer "i18n.load_path" do
      config.i18n.load_path.concat(Dir[File.expand_path("../locales/*.yml", __FILE__)])
    end
  end
end
