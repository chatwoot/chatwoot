FactoryBot.define do
  factory :webhook do
    account_id { 1 }
    inbox_id { 1 }
    url { 'https://api.chatwoot.com' }
    subscriptions do
      %w[
        conversation_status_changed
        conversation_updated
        conversation_created
        contact_created
        contact_updated
        message_created
        message_updated
        webwidget_triggered
      ]
    end
  end
end
