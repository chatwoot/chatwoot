require 'json'

class FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze
  ATTRIBUTE_TYPES = {
    date: 'date',
    text: 'text',
    number: 'numeric',
    link: 'text',
    list: 'text',
    checkbox: 'boolean'
  }.with_indifferent_access

  def initialize(params, user)
    @params = params
    @user = user
    file = File.read('./lib/filters/filter_keys.json')
    @filters = JSON.parse(file)
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
      @filter_values["value_#{current_index}"] = "%#{string_filter_values(query_hash)}%"
      like_filter_string(query_hash[:filter_operator], current_index)
    when 'is_present'
      @filter_values["value_#{current_index}"] = 'IS NOT NULL'
    when 'is_not_present'
      @filter_values["value_#{current_index}"] = 'IS NULL'
    when 'is_greater_than', 'is_less_than'
      @filter_values["value_#{current_index}"] = lt_gt_filter_values(query_hash)
    when 'days_before'
      @filter_values["value_#{current_index}"] = days_before_filter_values(query_hash)
    else
      @filter_values["value_#{current_index}"] = filter_values(query_hash).to_s
      "= :value_#{current_index}"
    end
  end

  def filter_values(query_hash)
    case query_hash['attribute_key']
    when 'status'
      return Conversation.statuses.values if query_hash['values'].include?('all')

      query_hash['values'].map { |x| Conversation.statuses[x.to_sym] }
    when 'message_type'
      query_hash['values'].map { |x| Message.message_types[x.to_sym] }
    when 'content'
      string_filter_values(query_hash)
    else
      query_hash['values']
    end
  end

  def string_filter_values(query_hash)
    return query_hash['values'][0].downcase if query_hash['values'].is_a?(Array)

    query_hash['values'].downcase
  end

  def lt_gt_filter_values(query_hash)
    attribute_key = query_hash[:attribute_key]
    attribute_model = query_hash['custom_attribute_type'].presence || self.class::ATTRIBUTE_MODEL
    attribute_type = custom_attribute(attribute_key, @account, attribute_model).try(:attribute_display_type)
    attribute_data_type = self.class::ATTRIBUTE_TYPES[attribute_type]
    value = query_hash['values'][0]
    operator = query_hash['filter_operator'] == 'is_less_than' ? '<' : '>'
    "#{operator} '#{value}'::#{attribute_data_type}"
  end

  def days_before_filter_values(query_hash)
    date = Time.zone.today - query_hash['values'][0].to_i.days
    query_hash['values'] = [date.strftime]
    query_hash['filter_operator'] = 'is_less_than'
    lt_gt_filter_values(query_hash)
  end

  def set_count_for_all_conversations
    [
      @conversations.assigned_to(@user).count,
      @conversations.unassigned.count,
      @conversations.count
    ]
  end

  def custom_attribute_query(query_hash, custom_attribute_type, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    attribute_model = custom_attribute_type.presence || self.class::ATTRIBUTE_MODEL

    attribute_type = custom_attribute(attribute_key, @account, attribute_model).try(:attribute_display_type)
    filter_operator_value = filter_operation(query_hash, current_index)
    attribute_data_type = self.class::ATTRIBUTE_TYPES[attribute_type]

    return ' ' if @custom_attribute.blank?

    table_name = attribute_model == 'conversation_attribute' ? 'conversations' : 'contacts'

    "  LOWER(#{table_name}.custom_attributes ->> '#{attribute_key}')::#{attribute_data_type} #{filter_operator_value} #{query_operator} "
  end

  private

  def custom_attribute(attribute_key, account, custom_attribute_type)
    current_account = account || Current.account
    attribute_model = custom_attribute_type.presence || self.class::ATTRIBUTE_MODEL
    @custom_attribute = current_account.custom_attribute_definitions.where(
      attribute_model: attribute_model
    ).find_by(attribute_key: attribute_key)
  end

  def equals_to_filter_string(filter_operator, current_index)
    return  "IN (:value_#{current_index})" if filter_operator == 'equal_to'

    "NOT IN (:value_#{current_index})"
  end

  def like_filter_string(filter_operator, current_index)
    return "LIKE :value_#{current_index}" if filter_operator == 'contains'

    "NOT LIKE :value_#{current_index}"
  end
end
