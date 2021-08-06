module MessageFormatHelper
  include RegexHelper
  def transform_user_mention_content(message_content)
    message_content.gsub(MENTION_REGEX, '\1')
  end

  def get_transformed_message_content(message)
    message.input_csat? "Please rate this conversation , #{ENV['FRONTEND_URL']}/survey/responses/#{message.conversation.uuid}"
  end
end
