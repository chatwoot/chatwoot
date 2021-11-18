class ConversationDrop < BaseDrop
  include MessageFormatHelper

  def display_id
    @obj.try(:display_id)
  end

  def recent_messages
    @obj.try(:recent_messages).map do |message|
      {
        'sender' => message.sender&.available_name || message.sender&.name,
        'content' => transform_user_mention_content(message.content),
        'attachments' => message.attachments.map(&:file_url)
      }
    end
  end
end
