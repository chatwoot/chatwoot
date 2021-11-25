class Contacts::FilterService < FilterService
  def perform
    @contacts = contact_query_builder

    {
      contacts: @contacts,
      count: {
        all_count: @contacts.count
      }
    }
  end

  def contact_query_builder
    contact_filters = @filters['contacts']

    @params[:payload].each_with_index do |query_hash, current_index|
      current_filter = contact_filters[query_hash['attribute_key']]
      @query_string += contact_query_string(current_filter, query_hash, current_index)
    end

    base_relation.where(@query_string, @filter_values.with_indifferent_access)
  end

  def contact_query_string(current_filter, query_hash, current_index)
    attribute_key = query_hash[:attribute_key]
    query_operator = query_hash[:query_operator]
    filter_operator_value = filter_operation(query_hash, current_index)

    case current_filter['attribute_type']
    when 'additional_attributes'
      " contacts.additional_attributes ->> '#{attribute_key}' #{filter_operator_value} #{query_operator} "
    when 'standard'
      if attribute_key == 'labels'
        " tags.id #{filter_operator_value} #{query_operator} "
      else
        " contacts.#{attribute_key} #{filter_operator_value} #{query_operator} "
      end
    end
  end

  def filter_values(query_hash)
    query_hash['values'][0]
  end

  def base_relation
    Current.account.contacts.left_outer_joins(:labels)
  end
end
