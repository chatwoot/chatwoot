# frozen_string_literal: true

module Sentry
  module CustomInspection
    def inspect
      attr_strings = (instance_variables - self.class::SKIP_INSPECTION_ATTRIBUTES).each_with_object([]) do |attr, result|
        value = instance_variable_get(attr)
        result << "#{attr}=#{value.inspect}" if value
      end

      "#<#{self.class.name} #{attr_strings.join(", ")}>"
    end
  end
end
