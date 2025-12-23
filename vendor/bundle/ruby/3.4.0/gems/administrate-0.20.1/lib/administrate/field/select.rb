require_relative "base"

module Administrate
  module Field
    class Select < Field::Base
      def self.searchable?
        true
      end

      def selectable_options
        values =
          if options.key?(:collection)
            options.fetch(:collection)
          elsif active_record_enum?
            active_record_enum_values
          else
            []
          end

        if values.respond_to? :call
          values = values.arity.positive? ? values.call(self) : values.call
        end

        values
      end

      def include_blank_option
        options.fetch(:include_blank, false)
      end

      def active_record_enum?
        resource.class.defined_enums.key?(attribute.to_s)
      end

      def active_record_enum_values
        resource.class.defined_enums[attribute.to_s].map(&:first)
      end
    end
  end
end
