require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class HelperGenerator < Base
      class_option :helper_specs, type: :boolean, default: true

      def generate_helper_spec
        return unless options[:helper_specs]

        template 'helper_spec.rb', target_path('helpers', class_path, "#{file_name}_helper_spec.rb")
      end
    end
  end
end
