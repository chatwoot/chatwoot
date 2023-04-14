class AddSendSignatureToInboxes < ActiveRecord::Migration[6.1]
  def change
    add_column :inboxes, :send_message_signature, :boolean, default: false
  end
end
