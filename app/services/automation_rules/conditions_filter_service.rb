require 'json'

class AutomationRules::ConditionsFilterService < FilterService
  def initialize(rule, conversation = nil)
    super([], nil)
    @rule = rule
    @conversation = conversation
    file = File.read('./lib/filters/filter_keys.json')
    @filters = JSON.parse(file)
  end

  def perform
    conversation_filters = @filters['conversations']
    contact_filters = @filters['contacts']

    @rule.conditions.each_with_index do |query_hash, current_index|
      conversation_filter = conversation_filters[query_hash['attribute_key']]
      contact_filter = contact_filters[query_hash['attribute_key']]

      if conversation_filter
        @query_string += conversation_query_string('conversations', conversation_filter, query_hash.with_indifferent_access, current_index)
      elsif contact_filter
        @query_string += conversation_query_string('contacts', contact_filter, query_hash.with_indifferent_access, current_index)
      end
    end

    records = base_relation.where(@query_string, @filter_values.with_indifferent_access)
    records.any?
  end

  def message_conditions
    message_filters = @filters['messages']

    @rule.conditions.each_with_index do |query_hash, current_index|
      current_filter = message_filters[query_hash['attribute_key']]
      @query_string += message_query_string(current_filter, query_hash.with_indifferent_access, current_index)
    end
    records = Message.where(conversation: @conversation).where(@query_string, @filter_values.with_indifferent_access)
    records.any?
  end

  def message_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']

    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'standard'
      " messages.#{attribute_key} #{filter_operator_value} #{query_operator} "
    end
  end

  # This will be used in future for contact automation rule
  def contact_conditions(_contact)
    conversation_filters = @filters['conversations']

    @rule.conditions.each_with_index do |query_hash, current_index|
      current_filter = conversation_filters[query_hash['attribute_key']]
      @query_string += conversation_query_string(current_filter, query_hash.with_indifferent_access, current_index)
    end

    records = base_relation.where(@query_string, @filter_values.with_indifferent_access)
    records.any?
  end

  def conversation_query_string(table_name, current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']
    filter_operator_value = filter_operation(query_hash, current_index)

    return custom_attribute_query(query_hash, 'contacts', current_index) if current_filter.nil?

    case current_filter['attribute_type']
    when 'additional_attributes'
      " #{table_name}.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.id #{filter_operator_value} #{query_operator} "
      else
        " #{table_name}.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  private

  def custom_attribute(attribute_key)
    @custom_attribute = Current.account.custom_attribute_definitions.find_by(attribute_key: attribute_key)
  end

  def base_relation
    Conversation.where(id: @conversation.id).joins('LEFT OUTER JOIN contacts on conversations.contact_id = contacts.id')
  end
end
