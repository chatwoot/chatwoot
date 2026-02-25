class AddNameToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :webhooks, :name, :string, null: true
  end
end
