module Searchkick
  class RecordData
    TYPE_KEYS = ["type", :type]

    attr_reader :index, :record

    def initialize(index, record)
      @index = index
      @record = record
    end

    def index_data
      data = record_data
      data[:data] = search_data
      {index: data}
    end

    def update_data(method_name)
      data = record_data
      data[:data] = {doc: search_data(method_name)}
      {update: data}
    end

    def delete_data
      {delete: record_data}
    end

    # custom id can be useful for load: false
    def search_id
      id = record.respond_to?(:search_document_id) ? record.search_document_id : record.id
      id.is_a?(Numeric) ? id : id.to_s
    end

    def document_type(ignore_type = false)
      index.klass_document_type(record.class, ignore_type)
    end

    def record_data
      data = {
        _index: index.name,
        _id: search_id
      }
      data[:routing] = record.search_routing if record.respond_to?(:search_routing)
      data
    end

    private

    def search_data(method_name = nil)
      partial_reindex = !method_name.nil?

      source = record.send(method_name || :search_data)

      # conversions
      index.conversions_fields.each do |conversions_field|
        if source[conversions_field]
          source[conversions_field] = source[conversions_field].map { |k, v| {query: k, count: v} }
        end
      end

      # hack to prevent generator field doesn't exist error
      if !partial_reindex
        index.suggest_fields.each do |field|
          if !source.key?(field) && !source.key?(field.to_sym)
            source[field] = nil
          end
        end
      end

      # locations
      index.locations_fields.each do |field|
        if source[field]
          if !source[field].is_a?(Hash) && (source[field].first.is_a?(Array) || source[field].first.is_a?(Hash))
            # multiple locations
            source[field] = source[field].map { |a| location_value(a) }
          else
            source[field] = location_value(source[field])
          end
        end
      end

      if index.options[:inheritance]
        if !TYPE_KEYS.any? { |tk| source.key?(tk) }
          source[:type] = document_type(true)
        end
      end

      cast_big_decimal(source)

      source
    end

    def location_value(value)
      if value.is_a?(Array)
        value.map(&:to_f).reverse
      elsif value.is_a?(Hash)
        {lat: value[:lat].to_f, lon: value[:lon].to_f}
      else
        value
      end
    end

    # change all BigDecimal values to floats due to
    # https://github.com/rails/rails/issues/6033
    # possible loss of precision :/
    def cast_big_decimal(obj)
      case obj
      when BigDecimal
        obj.to_f
      when Hash
        obj.each do |k, v|
          # performance
          if v.is_a?(BigDecimal)
            obj[k] = v.to_f
          elsif v.is_a?(Enumerable)
            obj[k] = cast_big_decimal(v)
          end
        end
      when Enumerable
        obj.map do |v|
          cast_big_decimal(v)
        end
      else
        obj
      end
    end
  end
end
