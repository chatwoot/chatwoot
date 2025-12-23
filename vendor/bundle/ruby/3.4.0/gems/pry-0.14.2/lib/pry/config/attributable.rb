# frozen_string_literal: true

class Pry
  class Config
    # Attributable provides the ability to create "attribute"
    # accessors. Attribute accessors create a standard "attr_writer" and a
    # customised "attr_reader". This reader is Proc-aware (lazy).
    #
    # @since v0.13.0
    # @api private
    module Attributable
      def attribute(attr_name)
        define_method(attr_name) do
          value = Config::Value.new(instance_variable_get("@#{attr_name}"))
          value.call
        end

        attr_writer(attr_name)
      end
    end
  end
end
