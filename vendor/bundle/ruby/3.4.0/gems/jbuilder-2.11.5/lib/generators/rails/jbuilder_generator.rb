require 'rails/generators/named_base'
require 'rails/generators/resource_helpers'

module Rails
  module Generators
    class JbuilderGenerator < NamedBase # :nodoc:
      include Rails::Generators::ResourceHelpers

      source_root File.expand_path('../templates', __FILE__)

      argument :attributes, type: :array, default: [], banner: 'field:type field:type'

      class_option :timestamps, type: :boolean, default: true

      def create_root_folder
        path = File.join('app/views', controller_file_path)
        empty_directory path unless File.directory?(path)
      end

      def copy_view_files
        %w(index show).each do |view|
          filename = filename_with_extensions(view)
          template filename, File.join('app/views', controller_file_path, filename)
        end
        template filename_with_extensions('partial'), File.join('app/views', controller_file_path, filename_with_extensions("_#{singular_table_name}"))
      end


      protected
        def attributes_names
          [:id] + super
        end

        def filename_with_extensions(name)
          [name, :json, :jbuilder] * '.'
        end

        def full_attributes_list
          if options[:timestamps]
            attributes_list(attributes_names + %w(created_at updated_at))
          else
            attributes_list(attributes_names)
          end
        end

        def attributes_list(attributes = attributes_names)
          if self.attributes.any? {|attr| attr.name == 'password' && attr.type == :digest}
            attributes = attributes.reject {|name| %w(password password_confirmation).include? name}
          end

          attributes.map { |a| ":#{a}"} * ', '
        end

        def virtual_attributes
          attributes.select {|name| name.respond_to?(:virtual?) && name.virtual? }
        end
    end
  end
end
