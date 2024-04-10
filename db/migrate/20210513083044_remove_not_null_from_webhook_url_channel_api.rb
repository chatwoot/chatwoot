class RemoveNotNullFromWebhookUrlChannelApi < ActiveRecord::Migration[6.0]
  def change
    change_column :channel_api, :webhook_url, :string, null: true
  end
end
