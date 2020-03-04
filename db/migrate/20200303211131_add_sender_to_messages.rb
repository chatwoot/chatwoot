class AddSenderToMessages < ActiveRecord::Migration[6.0]
  def change
    add_reference :messages, :sender, polymorphic: true, index: true

    ::Message.find_in_batches do |messages_batch|
      messages_batch.each do |message|
        if message.message_type == :template
          next
        elsif message.user.present? 
          message.sender = user 
        else
          message.sender = message.contact
        end
        message.save!
      end
    end
  end
end
