class CustomViewsListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation = event.data[:conversation]
    account = conversation.account

    dispatch_custom_filter_event(account)
  end

  def conversation_updated(event)
    conversation = event.data[:conversation]
    account = conversation.account

    dispatch_custom_filter_event(account)
  end

  private

  def dispatch_custom_filter_event(account)
    account.custom_filters.each do |filter|
      records = filter.filter_records

      next if (records[:count][:all_count]).zero? || records[:count][:all_count] == Redis::Alfred.get(filter.filter_count_key).to_i

      Redis::Alfred.set(filter.filter_count_key, records[:count][:all_count])

      Rails.configuration.dispatcher.dispatch(CUSTOM_FILTER_UPDATED, Time.zone.now, custom_filter: filter)
    end
  end
end
