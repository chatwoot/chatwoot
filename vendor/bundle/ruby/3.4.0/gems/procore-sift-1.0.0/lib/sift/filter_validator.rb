# Here be dragons:
# there are two forms of metaprogramming in this file
# instance variables are being dynamically set based on the param name
# and we are class evaling `validates` to create dynamic validations
# based on the filters being validated.
module Sift
  class FilterValidator
    include ActiveModel::Validations

    def self.build(filters:, sort_fields:, filter_params:, sort_params:)
      unique_validations_filters = filters.uniq(&:validation_field)

      klass = Class.new(self) do
        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        attr_accessor(*unique_validations_filters.map(&:validation_field))

        unique_validations_filters.each do |filter|
          if has_custom_validation?(filter, filter_params)
            validate filter.custom_validate
          elsif has_validation?(filter, filter_params, sort_fields)
            validates filter.validation_field.to_sym, filter.validation(sort_fields)
          end
        end
      end

      klass.new(filters, filter_params: filter_params, sort_params: sort_params)
    end

    def self.has_custom_validation?(filter, filter_params)
      filter_params[filter.validation_field] && filter.custom_validate
    end

    def self.has_validation?(filter, filter_params, sort_fields)
      (filter_params[filter.validation_field] && filter.validation(sort_fields)) || filter.validation_field == :sort
    end

    def initialize(filters, filter_params:, sort_params:)
      @filter_params = filter_params
      @sort_params = sort_params

      filters.each do |filter|
        instance_variable_set("@#{filter.validation_field}", to_type(filter))
      end
    end

    private

    attr_reader(:filter_params, :sort_params)

    def to_type(filter)
      if filter.type == :boolean
        ActiveRecord::Type::Boolean.new.cast(filter_params[filter.param])
      elsif filter.validation_field == :sort
        sort_params
      else
        filter_params[filter.param]
      end
    end
  end
end
