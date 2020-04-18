class AddSenderToMessages < ActiveRecord::Migration[6.0]
  def change
    add_reference :messages, :sender, polymorphic: true, index: true
    add_sender_from_message
  end

  def add_sender_from_message
    ::Message.find_in_batches do |messages_batch|
      messages_batch.each do |message|
        message.sender = message.user if message.user.present?
        message.sender = message.contact if message.contact.present?
        message.save!
      end
    end
  end
end
