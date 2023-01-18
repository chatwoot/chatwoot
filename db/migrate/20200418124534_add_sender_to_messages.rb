class AddSenderToMessages < ActiveRecord::Migration[6.0]
  def change
    add_reference :messages, :sender, polymorphic: true, index: true
    add_sender_from_message
    remove_index :messages, name: 'index_messages_on_contact_id', column: 'contact_id'
    remove_index :messages, name: 'index_messages_on_user_id', column: 'user_id'
    remove_column :messages, :user_id, :integer
    remove_column :messages, :contact_id, :integer
  end

  def add_sender_from_message
    ::Message.find_in_batches do |messages_batch|
      Rails.logger.info "migrated till #{messages_batch.first.id}\n"
      messages_batch.each do |message|
        # rubocop:disable Rails/SkipsModelValidations
        message.update_columns(sender_id: message.user.id, sender_type: 'User') if message.user.present?
        message.update_columns(sender_id: message.contact.id, sender_type: 'Contact') if message.contact.present?
        message.update_columns(sender_id: message.conversation.contact.id, sender_type: 'Contact') if message.sender.nil? && message.incoming?
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end
end
