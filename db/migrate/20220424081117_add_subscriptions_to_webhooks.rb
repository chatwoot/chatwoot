class AddSubscriptionsToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :subscriptions, :jsonb, default: [
      'conversation.status_changed',
      'conversation.updated',
      'conversation.created',
      'message.created',
      'message.updated',
      'webwidget.triggered'
    ]
  end
end
