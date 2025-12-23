require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class ViewGenerator < Base
      argument :actions, type: :array, default: [], banner: "action action"

      class_option :template_engine, desc: "Template engine to generate view files"

      def create_view_specs
        empty_directory target_path("views", file_path)

        actions.each do |action|
          @action = action
          template 'view_spec.rb',
                   target_path("views", file_path, "#{@action}.html.#{options[:template_engine]}_spec.rb")
        end
      end
    end
  end
end
