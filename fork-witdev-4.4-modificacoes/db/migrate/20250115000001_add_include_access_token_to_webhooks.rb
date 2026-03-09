class AddIncludeAccessTokenToWebhooks < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :include_access_token, :boolean, default: false, null: false
  end
end 