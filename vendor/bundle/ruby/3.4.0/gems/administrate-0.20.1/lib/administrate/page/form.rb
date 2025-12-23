require_relative "base"

module Administrate
  module Page
    class Form < Page::Base
      def initialize(dashboard, resource)
        super(dashboard)
        @resource = resource
      end

      attr_reader :resource

      def attributes(action = nil)
        attributes = dashboard.form_attributes(action)

        if attributes.is_a? Array
          attributes = { "" => attributes }
        end

        attributes.transform_values do |attrs|
          attrs.map do |attribute|
            attribute_field(dashboard, resource, attribute, :form)
          end
        end
      end

      def page_title
        dashboard.display_resource(resource)
      end

      private

      attr_reader :dashboard
    end
  end
end
