require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class ModelGenerator < Base
      argument :attributes,
               type: :array,
               default: [],
               banner: "field:type field:type"
      class_option :fixture, type: :boolean

      def create_model_spec
        template_file = target_path(
          'models',
          class_path,
          "#{file_name}_spec.rb"
        )
        template 'model_spec.rb', template_file
      end

      hook_for :fixture_replacement

      def create_fixture_file
        return unless missing_fixture_replacement?

        template 'fixtures.yml', target_path('fixtures', class_path, "#{(pluralize_table_names? ? plural_file_name : file_name)}.yml")
      end

    private

      def missing_fixture_replacement?
        options[:fixture] && options[:fixture_replacement].nil?
      end
    end
  end
end
