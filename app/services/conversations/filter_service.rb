class Conversations::FilterService < FilterService
  def perform
    conversation_query_builder
  end

  def conversation_query_builder
    conversation_filters = @filters['conversations']
    @params.each_with_index do |query_hash, current_index|
      query_hash = query_hash.with_indifferent_access
      current_filter = conversation_filters[query_hash['attribute_key']]
      @query_string += conversation_query_string(current_filter, query_hash, current_index)
    end

    base_relation.where(@query_string, @filter_values.with_indifferent_access)
  end

  def conversation_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " conversations.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.name #{filter_operator_value} #{query_operator} "
      else
        " conversations.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  def base_relation
    Conversation.left_outer_joins(:labels)
  end
end
