class AddNameToWebhooks < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :name, :string, null: true, if_not_exists: true
  end
end
