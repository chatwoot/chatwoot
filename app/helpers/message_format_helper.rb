module MessageFormatHelper
  include RegexHelper

  def transform_user_mention_content(message_content)
    # attachment message without content, message_content is nil
    message_content.presence ? message_content.gsub(MENTION_REGEX, '\1') : ''
  end

  def render_message_content(message_content)
    # rubocop:disable Rails/OutputSafety
    CommonMarker.render_html(message_content).html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
