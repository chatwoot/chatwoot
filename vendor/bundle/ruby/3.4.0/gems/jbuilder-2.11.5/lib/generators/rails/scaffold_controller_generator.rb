require 'rails/generators'
require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module Rails
  module Generators
    class ScaffoldControllerGenerator
      source_paths << File.expand_path('../templates', __FILE__)

      hook_for :jbuilder, type: :boolean, default: true

      private

        def permitted_params
          attributes_names.map { |name| ":#{name}" }.join(', ')
        end unless private_method_defined? :permitted_params
    end
  end
end
