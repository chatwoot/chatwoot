require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"

module Administrate
  class Search
    class Query
      attr_reader :filters, :valid_filters

      def blank?
        terms.blank? && filters.empty?
      end

      def initialize(original_query, valid_filters = nil)
        @original_query = original_query
        @valid_filters = valid_filters
        @filters, @terms = parse_query(original_query)
      end

      def original
        @original_query
      end

      def terms
        @terms.join(" ")
      end

      def to_s
        original
      end

      private

      def filter?(word)
        valid_filters&.any? { |filter| word.match?(/^#{filter}:/) }
      end

      def parse_query(query)
        filters = []
        terms = []
        query.to_s.split.each do |word|
          if filter?(word)
            filters << word
          else
            terms << word
          end
        end
        [filters, terms]
      end
    end

    def initialize(scoped_resource, dashboard, term)
      @dashboard = dashboard
      @scoped_resource = scoped_resource
      @query = Query.new(term, valid_filters.keys)
    end

    def run
      if query.blank?
        @scoped_resource.all
      else
        results = search_results(@scoped_resource)
        results = filter_results(results)
        results
      end
    end

    private

    def apply_filter(filter, filter_param, resources)
      return resources unless filter
      if filter.parameters.size == 1
        filter.call(resources)
      else
        filter.call(resources, filter_param)
      end
    end

    def filter_results(resources)
      query.filters.each do |filter_query|
        filter_name, filter_param = filter_query.split(":")
        filter = valid_filters[filter_name]
        resources = apply_filter(filter, filter_param, resources)
      end
      resources
    end

    def query_template
      search_attributes.map do |attr|
        table_name = query_table_name(attr)
        searchable_fields(attr).map do |field|
          column_name = column_to_query(field)
          "LOWER(CAST(#{table_name}.#{column_name} AS CHAR(256))) LIKE ?"
        end.join(" OR ")
      end.join(" OR ")
    end

    def searchable_fields(attr)
      return [attr] unless association_search?(attr)

      attribute_types[attr].searchable_fields
    end

    def query_values
      fields_count = search_attributes.sum do |attr|
        searchable_fields(attr).count
      end
      ["%#{term.mb_chars.downcase}%"] * fields_count
    end

    def search_attributes
      @dashboard.search_attributes
    end

    def search_results(resources)
      resources.
        left_joins(tables_to_join).
        where(query_template, *query_values)
    end

    def valid_filters
      if @dashboard.class.const_defined?(:COLLECTION_FILTERS)
        @dashboard.class.const_get(:COLLECTION_FILTERS).stringify_keys
      else
        {}
      end
    end

    def attribute_types
      @dashboard.class.const_get(:ATTRIBUTE_TYPES)
    end

    def query_table_name(attr)
      if association_search?(attr)
        provided_class_name = attribute_types[attr].options[:class_name]
        unquoted_table_name =
          if provided_class_name
            Administrate.warn_of_deprecated_option(:class_name)
            provided_class_name.constantize.table_name
          else
            @scoped_resource.reflect_on_association(attr).klass.table_name
          end
        ActiveRecord::Base.connection.quote_table_name(unquoted_table_name)
      else
        ActiveRecord::Base.connection.
          quote_table_name(@scoped_resource.table_name)
      end
    end

    def column_to_query(attr)
      ActiveRecord::Base.connection.quote_column_name(attr)
    end

    def tables_to_join
      attribute_types.keys.select do |attribute|
        attribute_types[attribute].searchable? && association_search?(attribute)
      end
    end

    def association_search?(attribute)
      attribute_types[attribute].associative?
    end

    def term
      query.terms
    end

    attr_reader :resolver, :query
  end
end
