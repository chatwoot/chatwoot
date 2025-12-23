require "rails/generators/named_base"

module FactoryBot
  module Generators
    class Base < Rails::Generators::NamedBase # :nodoc:
      def self.source_root
        path = File.join(
          File.dirname(__FILE__),
          "factory_bot",
          generator_name,
          "templates"
        )

        File.expand_path(path)
      end

      def factory_name
        class_name.gsub("::", "").underscore
      end

      def explicit_class_option
        return if class_name.underscore == factory_name

        ", class: '#{class_name}'"
      end
    end
  end
end
