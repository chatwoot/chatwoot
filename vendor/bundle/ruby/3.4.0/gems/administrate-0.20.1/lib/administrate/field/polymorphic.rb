require_relative "associative"

module Administrate
  module Field
    class Polymorphic < BelongsTo
      def self.permitted_attribute(attr, _options = {})
        { attr => %i{type value} }
      end

      def associated_resource_grouped_options
        classes.map do |klass|
          [klass.to_s, candidate_resources_for(klass).map do |resource|
            [display_candidate_resource(resource), resource.to_global_id]
          end]
        end
      end

      def permitted_attribute
        { attribute => %i{type value} }
      end

      def selected_global_id
        data ? data.to_global_id : nil
      end

      private

      def associated_dashboard(klass = data.class)
        "#{klass.name}Dashboard".constantize.new
      end

      def classes
        klasses = options.fetch(:classes, [])
        klasses.respond_to?(:call) ? klasses.call : klasses
      end

      private

      def order
        @_order ||= options.delete(:order)
      end

      def candidate_resources_for(klass)
        order ? klass.order(order) : klass.all
      end

      def display_candidate_resource(resource)
        associated_dashboard(resource.class).display_resource(resource)
      end
    end
  end
end
