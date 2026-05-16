class AddAdditionalHeadersToWebhookSurfaces < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :additional_headers, :jsonb, default: {}, null: false
    add_column :agent_bots, :additional_headers, :jsonb, default: {}, null: false
    add_column :channel_api, :additional_headers, :jsonb, default: {}, null: false
  end
end
