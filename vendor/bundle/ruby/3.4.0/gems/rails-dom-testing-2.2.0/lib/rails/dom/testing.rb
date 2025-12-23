# frozen_string_literal: true

require "nokogiri"
require "active_support"
require "active_support/core_ext/module/attribute_accessors"

require "rails/dom/testing/assertions"

module Rails
  module Dom
    module Testing
      mattr_accessor :default_html_version, default: :html4

      class << self
        def html5_support?
          defined?(Nokogiri::HTML5)
        end

        def html_document(html_version: nil)
          parser_classes = { html4: Nokogiri::HTML4::Document }
          parser_classes[:html5] = Nokogiri::HTML5::Document if html5_support?

          choose_html_parser(parser_classes, html_version: html_version)
        end

        def html_document_fragment(html_version: nil)
          parser_classes = { html4: Nokogiri::HTML4::DocumentFragment }
          parser_classes[:html5] = Nokogiri::HTML5::DocumentFragment if html5_support?

          choose_html_parser(parser_classes, html_version: html_version)
        end

        private
          def choose_html_parser(parser_classes, html_version: nil)
            html_version ||= Rails::Dom::Testing.default_html_version

            case html_version
            when :html4
              parser_classes[:html4]
            when :html5
              unless Rails::Dom::Testing.html5_support?
                raise NotImplementedError, "html5 parser is not supported on this platform"
              end
              parser_classes[:html5]
            else
              raise ArgumentError, "html_version must be :html4 or :html5, received #{html_version.inspect}"
            end
          end
      end
    end
  end
end
