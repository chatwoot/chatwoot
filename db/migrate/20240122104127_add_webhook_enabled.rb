class AddWebhookEnabled < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :enabled, :boolean, default: true
  end
end
