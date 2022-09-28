class AddSubscriptionsToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :subscriptions, :jsonb, default: %w[
      conversation_status_changed
      conversation_updated
      conversation_created
      message_created
      message_updated
      webwidget_triggered
    ]
  end
end
