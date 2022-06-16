class Conversations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

  def perform
    @conversations = conversation_query_builder
    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  def conversation_query_builder
    conversation_filters = @filters['conversations']
    @params[:payload].each_with_index do |query_hash, current_index|
      current_filter = conversation_filters[query_hash['attribute_key']]
      @query_string += conversation_query_string(current_filter, query_hash, current_index)
    end

    base_relation.where(@query_string, @filter_values.with_indifferent_access)
  end

  def conversation_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    filter_operator_value = filter_operation(query_hash, current_index)

    return custom_attribute_query(query_hash, 'conversation_attribute', current_index) if current_filter.nil?

    case current_filter['attribute_type']
    when 'additional_attributes'
      " conversations.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'date_attributes'
      " (conversations.#{attribute_key})::#{current_filter['data_type']} #{filter_operator_value}#{current_filter['data_type']} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.name #{filter_operator_value} #{query_operator} "
      else
        " conversations.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  def base_relation
    Current.account.conversations.left_outer_joins(:labels)
  end

  def current_page
    @params[:page] || 1
  end

  def conversations
    @conversations = @conversations.includes(
      :taggings, :inbox, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team
    )
    @conversations.latest.page(current_page)
  end
end
