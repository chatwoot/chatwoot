require "administrate/view_generator"

module Administrate
  module Generators
    module Views
      class FieldGenerator < Administrate::ViewGenerator
        def self.template_source_path
          File.expand_path(
            "../../../../../app/views/fields/",
            __FILE__,
          )
        end

        source_root template_source_path

        def copy_partials
          resource_path = args.first.try(:underscore)

          if resource_path == "all"
            entries = Dir.entries(self.class.template_source_path)
            field_types = entries.reject { |name| name[0] == "." }

            field_types.each do |field_type|
              copy_field_partials(field_type)
            end
          else
            copy_field_partials(resource_path)
          end
        end

        private

        def copy_field_partials(resource_path)
          copy_field_partial(resource_path, :index)
          copy_field_partial(resource_path, :show)
          copy_field_partial(resource_path, :form)
        end

        def copy_field_partial(resource_path, partial_name)
          template_file = "#{resource_path}/_#{partial_name}.html.erb"

          copy_file(
            template_file,
            "app/views/fields/#{template_file}",
          )
        end
      end
    end
  end
end
