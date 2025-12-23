require "sift/filter"
require "sift/filter_validator"
require "sift/filtrator"
require "sift/sort"
require "sift/subset_comparator"
require "sift/type_validator"
require "sift/parameter"
require "sift/value_parser"
require "sift/scope_handler"
require "sift/where_handler"
require "sift/validators/valid_int_validator"
require "sift/validators/valid_date_range_validator"
require "sift/validators/valid_json_validator"

module Sift
  extend ActiveSupport::Concern

  def filtrate(collection)
    Filtrator.filter(collection, params, filters)
  end

  def filter_params
    params.fetch(:filters, {})
  end

  def sort_params
    params.fetch(:sort, "").split(",") if filters.any? { |filter| filter.is_a?(Sort) }
  end

  def filters_valid?
    filter_validator.valid?
  end

  def filter_errors
    filter_validator.errors.messages
  end

  private

  def filter_validator
    @_filter_validator ||= FilterValidator.build(
      filters: filters,
      sort_fields: sort_fields,
      filter_params: filter_params,
      sort_params: sort_params,
    )
  end

  def filters
    self.class.ancestors
      .take_while { |klass| klass.name != "Sift" }
      .flat_map { |klass| klass.try(:filters) }
      .compact
      .uniq { |f| [f.param, f.class] }
  end

  def sorts_exist?
    filters.any? { |filter| filter.is_a?(Sort) }
  end

  def sort_fields
    self.class.ancestors
      .take_while { |klass| klass.name != "Sift" }
      .flat_map { |klass| klass.try(:sort_fields) }
      .compact
  end

  class_methods do
    def filter_on(parameter, type:, internal_name: parameter, default: nil, validate: nil, scope_params: [], tap: nil)
      filters << Filter.new(parameter, type, internal_name, default, validate, scope_params, tap)
    end

    def filters
      @_filters ||= []
    end

    # TODO: this is only used in tests, can I kill it?
    def reset_filters
      @_filters = []
    end

    def sort_fields
      @_sort_fields ||= []
    end

    def sort_on(parameter, type:, internal_name: parameter, scope_params: [])
      filters << Sort.new(parameter, type, internal_name, scope_params)
      sort_fields << parameter.to_s
      sort_fields << "-#{parameter}"
    end
  end
end
