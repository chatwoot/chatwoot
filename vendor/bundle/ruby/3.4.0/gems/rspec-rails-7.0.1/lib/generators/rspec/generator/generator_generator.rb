require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class GeneratorGenerator < Base
      class_option :generator_specs, type: :boolean, default: true, desc: 'Generate generator specs'

      def generate_generator_spec
        return unless options[:generator_specs]

        template template_name, target_path('generator', class_path, filename)
      end

      def template_name
        'generator_spec.rb'
      end

      def filename
        "#{file_name}_generator_spec.rb"
      end
    end
  end
end
