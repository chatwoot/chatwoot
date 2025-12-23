require_relative "base"

module Administrate
  module Page
    class Show < Page::Base
      def initialize(dashboard, resource)
        super(dashboard)
        @resource = resource
      end

      attr_reader :resource

      def page_title
        dashboard.display_resource(resource)
      end

      def attributes
        attributes = dashboard.show_page_attributes

        if attributes.is_a? Array
          attributes = { "" => attributes }
        end

        attributes.transform_values do |attrs|
          attrs.map do |attr_name|
            attribute_field(dashboard, resource, attr_name, :show)
          end
        end
      end
    end
  end
end
