class ChangeWebhookUrlToText < ActiveRecord::Migration[7.1]
  def up
    change_column :webhooks, :url, :text
  end

  def down
    change_column :webhooks, :url, :string
  end
end
