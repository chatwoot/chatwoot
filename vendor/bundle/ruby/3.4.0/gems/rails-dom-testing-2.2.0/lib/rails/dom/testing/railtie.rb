# frozen_string_literal: true

module Rails
  module Dom
    module Testing
      class Railtie < Rails::Railtie # :nodoc:
        config.after_initialize do |app|
          version = app.config.try(:dom_testing_default_html_version) # Rails 7.1+
          Rails::Dom::Testing.default_html_version = version if version
        end
      end
    end
  end
end
