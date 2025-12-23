# frozen_string_literal: true

require_relative "rails/html/sanitizer/version"

require "loofah"

require_relative "rails/html/scrubbers"
require_relative "rails/html/sanitizer"

module Rails
  Html = HTML # :nodoc:
end

module ActionView
  module Helpers
    module SanitizeHelper
      module ClassMethods
        # Replaces the allowed tags for the +sanitize+ helper.
        #
        #   class Application < Rails::Application
        #     config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
        #   end
        #
        def sanitized_allowed_tags=(tags)
          sanitizer_vendor.safe_list_sanitizer.allowed_tags = tags
        end

        # Replaces the allowed HTML attributes for the +sanitize+ helper.
        #
        #   class Application < Rails::Application
        #     config.action_view.sanitized_allowed_attributes = ['onclick', 'longdesc']
        #   end
        #
        def sanitized_allowed_attributes=(attributes)
          sanitizer_vendor.safe_list_sanitizer.allowed_attributes = attributes
        end

        [:protocol_separator,
         :uri_attributes,
         :bad_tags,
         :allowed_css_properties,
         :allowed_css_keywords,
         :shorthand_css_properties,
         :allowed_protocols].each do |meth|
          meth_name = "sanitized_#{meth}"

          define_method(meth_name) { deprecate_option(meth_name) }
          define_method("#{meth_name}=") { |_| deprecate_option("#{meth_name}=") }
        end

        private
          def deprecate_option(name)
            ActiveSupport::Deprecation.warn "The #{name} option is deprecated " \
              "and has no effect. Until Rails 5 the old behavior can still be " \
              "installed. To do this add the `rails-deprecated-sanitizer` to " \
              "your Gemfile. Consult the Rails 4.2 upgrade guide for more information."
          end
      end
    end
  end
end
