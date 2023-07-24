class RemoveMessageSignatureEnabled < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :message_signature_enabled, :boolean
  end
end
