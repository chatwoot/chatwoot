require "administrate/view_generator"

module Administrate
  module Generators
    module Views
      class FormGenerator < Administrate::ViewGenerator
        source_root template_source_path

        def copy_form
          copy_resource_template("_form")
        end
      end
    end
  end
end
