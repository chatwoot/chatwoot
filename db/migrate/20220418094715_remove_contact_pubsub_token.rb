class RemoveContactPubsubToken < ActiveRecord::Migration[6.1]
  def change
    remove_column :contacts, :pubsub_token, :string
  end
end
