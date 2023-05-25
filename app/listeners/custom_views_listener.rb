class CustomViewsListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    account = conversation.account

    account.custom_filters.each do |filter|
      records = filter.filter_records

      unless records[:count][:all_count] == Redis::Alfred.get(filter.filter_count_key)
        Redis::Alfred.set(filter.filter_count_key, records[:count][:all_count])

        Rails.configuration.dispatcher.dispatch(CUSTOM_FILTER_UPDATED, Time.zone.now, custom_filter: filter)
      end
    end
  end
end
