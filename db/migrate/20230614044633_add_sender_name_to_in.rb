class AddSenderNameToIn < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :business_name, :string, null: true
  end
end
