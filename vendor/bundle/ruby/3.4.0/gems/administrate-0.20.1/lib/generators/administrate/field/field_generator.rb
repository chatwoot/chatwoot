module Administrate
  module Generators
    class FieldGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../templates", __FILE__)

      def template_field_object
        template(
          "field_object.rb.erb",
          "app/fields/#{file_name}_field.rb",
        )
      end

      def copy_partials
        copy_partial(:show)
        copy_partial(:index)
        copy_partial(:form)
      end

      private

      def copy_partial(partial_name)
        partial = "_#{partial_name}.html.erb"

        copy_file(
          partial,
          "app/views/fields/#{file_name}_field/#{partial}",
        )
      end
    end
  end
end
