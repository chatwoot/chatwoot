FactoryBot.define do
  factory :webhook do
    account
    inbox { nil }
    url { 'https://api.chatwoot.com' }
    name { 'My Webhook' }
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
