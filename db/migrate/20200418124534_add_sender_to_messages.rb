class AddSenderToMessages < ActiveRecord::Migration[6.0]
  def change
    add_reference :messages, :sender, polymorphic: true, index: true
    add_sender_from_message
    remove_index :messages, name: 'index_messages_on_contact_id', column: 'contact_id'
    remove_index :messages, name: 'index_messages_on_user_id', column: 'user_id'
    remove_column :messages, :user_id, :integer # rubocop:disable Rails/BulkChangeTable
    remove_column :messages, :contact_id, :integer
  end

  def add_sender_from_message
    ::Message.find_in_batches do |messages_batch|
      messages_batch.each do |message|
        message.sender = message.user if message.user.present?
        message.sender = message.contact if message.contact.present?
        if message.sender.nil?
          message.sender = message.conversation.contact if message.incoming?
        end
        message.save!
      end
    end
  end
end
