require "administrate/view_generator"

module Administrate
  module Generators
    class ViewsGenerator < Administrate::ViewGenerator
      def copy_templates
        view = "administrate:views:"
        call_generator("#{view}index", resource_path, "--namespace", namespace)
        call_generator("#{view}show", resource_path, "--namespace", namespace)
        call_generator("#{view}new", resource_path, "--namespace", namespace)
        call_generator("#{view}edit", resource_path, "--namespace", namespace)
      end
    end
  end
end
