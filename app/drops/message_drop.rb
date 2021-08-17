class MessageDrop < BaseDrop
  include MessageFormatHelper

  def sender_display_name
    @obj.sender.try(:display_name)
  end

  def text_content
    content = @obj.try(:content)
    transform_user_mention_content content
  end
end
