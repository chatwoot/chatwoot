class CustomViewsListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation = event.data[:conversation]
    account = conversation.account

    account.custom_filters.each do |filter|
      records = filter.filter_records

      next if records[:count][:all_count] == 0

      next unless conversation_belongs_to_filtered_records?(records, conversation)

      unless records[:count][:all_count] == Redis::Alfred.get(filter.filter_count_key).to_i
        Redis::Alfred.set(filter.filter_count_key, records[:count][:all_count])

        Rails.configuration.dispatcher.dispatch(CUSTOM_FILTER_UPDATED, Time.zone.now, custom_filter: filter)
      end
    end
  end

  private

  def conversation_belongs_to_filtered_records?(records, conversation)
    conversations = records[:conversations].pluck(:id)
    conversations.include?(conversation.id)
  end
end
