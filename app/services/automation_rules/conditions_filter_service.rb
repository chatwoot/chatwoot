require 'json'

class AutomationRules::ConditionsFilterService < FilterService
  def initialize(rule, conversation)
    super([], nil)
    @rule = rule
    @conversation = conversation
    file = File.read('./lib/filters/filter_keys.json')
    @filters = JSON.parse(file)
  end

  def perform
    conversation_filters = @filters['conversations']

    @rule.conditions.each_with_index do |query_hash, current_index|
      current_filter = conversation_filters[query_hash['attribute_key']]
      @query_string += conversation_query_string(current_filter, query_hash.with_indifferent_access, current_index)
    end

    records = base_relation.where(@query_string, @filter_values.with_indifferent_access)
    records.any?
  end

  def conversation_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash['attribute_key']
    query_operator = query_hash['query_operator']

    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " conversations.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.id #{filter_operator_value} #{query_operator} "
      else
        " conversations.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  def base_relation
    Conversation.where(id: @conversation)
  end
end
