class UpdateDefaultOnSubscriptionsWebhooks < ActiveRecord::Migration[6.1]
  def change
    change_column_default :webhooks, :subscriptions,
                          from: %w[conversation_status_changed conversation_updated conversation_created
                                   message_created message_updated webwidget_triggered],
                          to: %w[conversation_status_changed conversation_updated conversation_created
                                 contact_created contact_updated message_created message_updated webwidget_triggered]
  end
end
