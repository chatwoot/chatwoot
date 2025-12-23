require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class SystemGenerator < Base
      class_option :system_specs, type: :boolean, default: true,  desc: "Generate system specs"

      def generate_system_spec
        return unless options[:system_specs]

        template template_name, target_path('system', class_path, filename)
      end

      def template_name
        'system_spec.rb'
      end

      def filename
        "#{table_name}_spec.rb"
      end
    end
  end
end
