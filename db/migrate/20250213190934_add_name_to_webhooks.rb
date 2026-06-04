class AddNameToWebhooks < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :name, :string, null: true
  end
end
