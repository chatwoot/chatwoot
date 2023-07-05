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
    account.custom_filters.each(&:update_filter_conversation_count)
  end
end
