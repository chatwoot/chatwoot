module Sift
  # Filter describes the way a parameter maps to a database column
  # and the type information helpful for validating input.
  class Filter
    attr_reader :parameter, :default, :custom_validate, :scope_params

    def initialize(param, type, internal_name, default, custom_validate = nil, scope_params = [], tap = ->(value, _params) { value })
      @parameter = Parameter.new(param, type, internal_name)
      @default = default
      @custom_validate = custom_validate
      @scope_params = scope_params
      @tap = tap
      raise ArgumentError, "scope_params must be an array of symbols" unless valid_scope_params?(scope_params)
      raise "unknown filter type: #{type}" unless type_validator.valid_type?
    end

    def validation(_sort)
      type_validator.validate
    end

    # rubocop:disable Lint/UnusedMethodArgument
    def apply!(collection, value:, active_sorts_hash:, params: {})
      if not_processable?(value)
        collection
      elsif should_apply_default?(value)
        default.call(collection)
      else
        parameterized_values = parameterize(value)
        processed_values = @tap.present? ? @tap.call(parameterized_values, params) : parameterized_values
        handler.call(collection, processed_values, params, scope_params)
      end
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def always_active?
      false
    end

    def validation_field
      parameter.param
    end

    def type_validator
      @type_validator ||= Sift::TypeValidator.new(param, type)
    end

    def type
      parameter.type
    end

    def param
      parameter.param
    end

    private

    def parameterize(value)
      ValueParser.new(value: value, type: parameter.type, options: parameter.parse_options).parse
    end

    def not_processable?(value)
      value.nil? && default.nil?
    end

    def should_apply_default?(value)
      value.nil? && !default.nil?
    end

    def mapped_scope_params(params)
      scope_params.each_with_object({}) do |scope_param, hash|
        hash[scope_param] = params.fetch(scope_param)
      end
    end

    def valid_scope_params?(scope_params)
      scope_params.is_a?(Array) && scope_params.all? { |symbol| symbol.is_a?(Symbol) }
    end

    def handler
      parameter.handler
    end

    def supports_ranges?
      parameter.supports_ranges?
    end
  end
end
