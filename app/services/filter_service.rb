require 'json'

class FilterService
  include Filters::FilterHelper
  include Filters::CustomAttributeFilterHelper
  include CustomExceptions::CustomFilter

  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze
  ATTRIBUTE_TYPES = {
    date: 'date', text: 'text', number: 'numeric', link: 'text', list: 'text', checkbox: 'boolean'
  }.with_indifferent_access

  def initialize(params, user)
    @params = params
    @user = user
    file = File.read('./lib/filters/filter_keys.yml')
    @filters = YAML.safe_load(file)
    @query_string = ''
    @filter_values = {}
  end

  def perform; end

  def filter_operation(query_hash, current_index)
    case query_hash[:filter_operator]
    when 'equal_to', 'not_equal_to'
      @filter_values["value_#{current_index}"] = filter_values(query_hash)
      equals_to_filter_string(query_hash[:filter_operator], current_index)
    when 'contains', 'does_not_contain'
      @filter_values["value_#{current_index}"] = values_for_ilike(query_hash)
      ilike_filter_string(query_hash[:filter_operator], current_index)
    when 'is_present'
      @filter_values["value_#{current_index}"] = 'IS NOT NULL'
    when 'is_not_present'
      @filter_values["value_#{current_index}"] = 'IS NULL'
    when 'is_greater_than', 'is_less_than'
      lt_gt_filter_query(query_hash, current_index)
    when 'days_before'
      days_before_filter_query(query_hash, current_index)
    else
      @filter_values["value_#{current_index}"] = filter_values(query_hash).to_s
      "= :value_#{current_index}"
    end
  end

  def filter_values(query_hash)
    attribute_key = query_hash['attribute_key']
    values = query_hash['values']

    return conversation_status_values(values) if attribute_key == 'status'
    return conversation_priority_values(values) if attribute_key == 'priority'
    return message_type_values(values) if attribute_key == 'message_type'
    return downcase_array_values(values) if attribute_key == 'content'

    case_insensitive_values(query_hash)
  end

  def downcase_array_values(values)
    values.map(&:downcase)
  end

  def case_insensitive_values(query_hash)
    if @custom_attribute_type.present? && query_hash['values'][0].is_a?(String)
      string_filter_values(query_hash)
    else
      query_hash['values']
    end
  end

  def values_for_ilike(query_hash)
    if query_hash['values'].is_a?(Array)
      query_hash['values']
        .map { |item| "%#{item.strip}%" }
    else
      ["%#{query_hash['values'].strip}%"]
    end
  end

  def string_filter_values(query_hash)
    return query_hash['values'][0].downcase if query_hash['values'].is_a?(Array)

    query_hash['values'].downcase
  end

  def lt_gt_filter_query(query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    attribute_model = query_hash['custom_attribute_type'].presence || self.class::ATTRIBUTE_MODEL
    attribute_type = custom_attribute(attribute_key, @account, attribute_model).try(:attribute_display_type)
    attribute_data_type = self.class::ATTRIBUTE_TYPES[attribute_type] || standard_attribute_data_type(attribute_key)

    @filter_values["value_#{current_index}"] = coerce_lt_gt_value(
      query_hash['values'][0],
      attribute_data_type,
      attribute_key
    )
    operator = query_hash['filter_operator'] == 'is_less_than' ? '<' : '>'
    "#{operator} :value_#{current_index}"
  end

  def days_before_filter_query(query_hash, current_index)
    date = Time.zone.today - query_hash['values'][0].to_i.days
    updated_query_hash = query_hash.with_indifferent_access.merge(
      values: [date.strftime],
      filter_operator: 'is_less_than'
    )

    lt_gt_filter_query(updated_query_hash, current_index)
  end

  def set_count_for_all_conversations
    [
      @conversations.assigned_to(@user).count,
      @conversations.unassigned.count,
      @conversations.count
    ]
  end

  def tag_filter_query(query_hash, current_index)
    model_name = filter_config[:entity]
    table_name = filter_config[:table_name]
    query_operator = query_hash[:query_operator]
    @filter_values["value_#{current_index}"] = filter_values(query_hash)

    tag_model_relation_query =
      "SELECT * FROM taggings WHERE taggings.taggable_id = #{table_name}.id AND taggings.taggable_type = '#{model_name}'"
    tag_query =
      "AND taggings.tag_id IN (SELECT tags.id FROM tags WHERE tags.name IN (:value_#{current_index}))"

    case query_hash[:filter_operator]
    when 'equal_to'
      "EXISTS (#{tag_model_relation_query} #{tag_query}) #{query_operator}"
    when 'not_equal_to'
      "NOT EXISTS (#{tag_model_relation_query} #{tag_query}) #{query_operator}"
    when 'is_present'
      "EXISTS (#{tag_model_relation_query}) #{query_operator}"
    when 'is_not_present'
      "NOT EXISTS (#{tag_model_relation_query}) #{query_operator}"
    end
  end

  private

  def standard_attribute_data_type(attribute_key)
    @filters.each_value do |section|
      return section.dig(attribute_key, 'data_type') if section.is_a?(Hash) && section.key?(attribute_key)
    end
    nil
  end

  def coerce_lt_gt_value(raw_value, attribute_data_type, attribute_key)
    case attribute_data_type
    when 'date'
      Date.iso8601(raw_value.to_s)
    when 'numeric'
      BigDecimal(raw_value.to_s)
    else
      raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: attribute_key)
    end
  rescue  ArgumentError, FloatDomainError, TypeError
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: attribute_key)
  end

  def equals_to_filter_string(filter_operator, current_index)
    return  "IN (:value_#{current_index})" if filter_operator == 'equal_to'

    "NOT IN (:value_#{current_index})"
  end

  def ilike_filter_string(filter_operator, current_index)
    return "ILIKE ANY (ARRAY[:value_#{current_index}])" if %w[contains].include?(filter_operator)

    "NOT ILIKE ALL (ARRAY[:value_#{current_index}])"
  end

  def like_filter_string(filter_operator, current_index)
    return "LIKE :value_#{current_index}" if %w[contains starts_with].include?(filter_operator)

    "NOT LIKE :value_#{current_index}"
  end

  def query_builder(model_filters)
    @params[:payload].each_with_index do |query_hash, current_index|
      @query_string += " #{build_condition_query(model_filters, query_hash, current_index).strip}"
    end
    base_relation.where(@query_string, @filter_values.with_indifferent_access)
  end

  def validate_query_operator
    @params[:payload].each do |query_hash|
      validate_single_condition(query_hash)
    end
  end
end
