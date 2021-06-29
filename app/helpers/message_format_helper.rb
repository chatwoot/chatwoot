module MessageFormatHelper
  include RegexHelper
  def transform_user_mention_content(message_content)
    message_content.gsub(MENTION_REGEX, '\1')
  end
end
