require "rails/generators/base"

class SentryGenerator < ::Rails::Generators::Base
  class_option :dsn, type: :string, desc: "Sentry DSN"

  class_option :inject_meta, type: :boolean, default: true, desc: "Inject meta tag into layout"

  def copy_initializer_file
    dsn = options[:dsn] ? "'#{options[:dsn]}'" : "ENV['SENTRY_DSN']"

    create_file "config/initializers/sentry.rb", <<~RUBY
      # frozen_string_literal: true

      Sentry.init do |config|
        config.breadcrumbs_logger = [:active_support_logger]
        config.dsn = #{dsn}
        config.enable_tracing = true
      end
    RUBY
  end

  def inject_code_into_layout
    return unless options[:inject_meta]

    inject_into_file "app/views/layouts/application.html.erb", before: "</head>\n" do
      "  <%= Sentry.get_trace_propagation_meta.html_safe %>\n  "
    end
  end
end
