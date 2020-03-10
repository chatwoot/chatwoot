class AddTypeToWebhook < ActiveRecord::Migration[6.0]
  def change
    add_column :webhooks, :webhook_type, :integer, default: '0'
  end
end
