require 'json'

class FilterService

  def initialize(type, params, user)
    @type = type
    @params = params
    @user = user
    file = File.read('./lib/filters/filter_keys.json')
    @filters = JSON.parse(file)
    @query_string = ''
    @filter_values = {}
  end

  def perform
    case @type
    when 'conversation'
      conversation_query_builder
      Conversation.limit(10)
    when 'contact'
      Contact.limit(10)
    end
  end

  ## Might move this conversation query builder
  def conversation_query_builder
    conversation_filters = @filters['conversations']
    @params.each_with_index do |query_hash, current_index|
      current_filter = conversation_filters[query_hash[:attribute_key]]
      @query_string = @query_string + conversation_query_string(current_filter, query_hash, current_index)
    end

    Conversation.where(@query_string,  @filter_values.with_indifferent_access)
  end

  def conversation_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    # attribute_type =
    filter_operator_value = filter_operation(query_hash, current_index)
    # @filter_values << filter_value(query_hash)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " conversations.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      " conversations.#{attribute_key} #{filter_operator_value} #{query_operator} "
    end
  end

  def filter_operation(query_hash, current_index)
    case query_hash[:filter_operator]
    when 'equal_to'
      @filter_values["value_#{current_index}"] = query_hash[:values]
      "= :value_#{current_index}"
    when 'not_equal_to'
      @filter_values["value_#{current_index}"] = query_hash[:values]
      "!= :value_#{current_index}"
    when 'contains'
      @filter_values["value_#{current_index}"] = "%#{query_hash[:values]}%"
      "LIKE :value_#{current_index}"
    when 'does_not_contain'
      @filter_values["value_#{current_index}"] = "%#{query_hash[:values]}%"
      "NOT LIKE :value_#{current_index}"
    else
      @filter_values["value_#{current_index}"] = "#{query_hash[:values]}"
      "= :value_#{current_index}"
    end
  end

  def filter_value(query_hash)
    case query_hash[:filter_operator]
    when 'equal_to', "not_equal_to"
      @filter_values["value_#{index}"] = "#{query_hash[:values]}"
    when 'contains', 'does_not_contain'
      @filter_values["value_#{index}"] = "%#{query_hash[:values]}%"
    else
      @filter_values["value_#{index}"] =  "#{query_hash[:values]}"
    end
  end

end
