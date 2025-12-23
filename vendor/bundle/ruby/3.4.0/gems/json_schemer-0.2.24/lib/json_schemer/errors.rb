# Based on code from @robacarp found in issue 48:
# https://github.com/davishmcclurg/json_schemer/issues/48
#
module JSONSchemer
  module Errors
    class << self
      def pretty(error)
        data_pointer, type, schema = error.values_at('data_pointer', 'type', 'schema')
        location = data_pointer.empty? ? 'root' : "property '#{data_pointer}'"

        case type
        when 'required'
          keys = error.fetch('details').fetch('missing_keys').join(', ')
          "#{location} is missing required keys: #{keys}"
        when 'null', 'string', 'boolean', 'integer', 'number', 'array', 'object'
          "#{location} is not of type: #{type}"
        when 'pattern'
          "#{location} does not match pattern: #{schema.fetch('pattern')}"
        when 'format'
          "#{location} does not match format: #{schema.fetch('format')}"
        when 'const'
          "#{location} is not: #{schema.fetch('const').inspect}"
        when 'enum'
          "#{location} is not one of: #{schema.fetch('enum')}"
        else
          "#{location} is invalid: error_type=#{type}"
        end
      end
    end
  end
end
