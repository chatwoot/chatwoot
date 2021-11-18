require 'json'

class FilterService
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
      @filter_values["value_#{current_index}"] = "%#{filter_values(query_hash)}%"
      like_filter_string(query_hash[:filter_operator], current_index)
    when 'is_present'
      @filter_values["value_#{current_index}"] = 'IS NOT NULL'
    when 'is_not_present'
      @filter_values["value_#{current_index}"] = 'IS NULL'
    else
      @filter_values["value_#{current_index}"] = filter_values(query_hash).to_s
      "= :value_#{current_index}"
    end
  end

  def filter_values(query_hash)
    if query_hash['attribute_key'] == 'status'
      return Conversation.statuses.values if query_hash['values'].include?('all')

      query_hash['values'].map { |x| Conversation.statuses[x.to_sym] }
    else
      query_hash['values']
    end
  end

  def set_count_for_all_conversations
    [
      @conversations.assigned_to(@user).count,
      @conversations.unassigned.count,
      @conversations.count
    ]
  end

  private

  def equals_to_filter_string(filter_operator, current_index)
    return  "IN (:value_#{current_index})" if filter_operator == 'equal_to'

    "NOT IN (:value_#{current_index})"
  end

  def like_filter_string(filter_operator, current_index)
    return "LIKE :value_#{current_index}" if filter_operator == 'contains'

    "NOT LIKE :value_#{current_index}"
  end
end
