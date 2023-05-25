class CustomViewsListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    account = conversation.account

    account.custom_filters.each do |filter|
      conversations = Conversation.where(id: conversation.id)

      records = Conversations::FilterService.new(
        filter.query.with_indifferent_access, Current.user
      ).conversation_query_builder(conversations)

      filters = []
      filters << filter.id if records.present?
    end

    # Update redis

    # ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, payload)
  end
end
