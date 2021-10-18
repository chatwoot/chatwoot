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
    when 'equal_to'
      @filter_values["value_#{current_index}"] = filter_values(query_hash)
      "IN (:value_#{current_index})"
    when 'not_equal_to'
      @filter_values["value_#{current_index}"] = filter_values(query_hash)
      "NOT IN (:value_#{current_index})"
    when 'contains'
      @filter_values["value_#{current_index}"] = "%#{filter_values(query_hash)}%"
      "LIKE :value_#{current_index}"
    when 'does_not_contain'
      @filter_values["value_#{current_index}"] = "%#{filter_values(query_hash)}%"
      "NOT LIKE :value_#{current_index}"
    else
      @filter_values["value_#{current_index}"] = filter_values(query_hash).to_s
      "= :value_#{current_index}"
    end
  end

  def filter_values(query_hash)
    values = query_hash['values'].map { |x| x['name'].downcase }

    if query_hash['attribute_key'] == 'status'
      values.collect { |v| Conversation.statuses[v] }
    else
      values
    end
  end
end
