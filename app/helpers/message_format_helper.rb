module MessageFormatHelper
  include RegexHelper

  def transform_user_mention_content(message_content)
    # attachment message without content, message_content is nil
    return '' unless message_content.presence

    # Transform mention markdown links to plain text for notifications
    # Converts: [@👍 customer support](mention://team/1/%F0%9F%91%8D%20customer%20support)
    # To: @👍 customer support
    message_content.gsub(MENTION_REGEX) do |_match|
      display_name = Regexp.last_match(1)  # Already formatted display name with @

      # Use the display name from the markdown link text, which is already properly formatted
      # This preserves emojis and spacing as they appear in the frontend
      display_name
    end
  end

  def render_message_content(message_content)
    ChatwootMarkdownRenderer.new(message_content).render_message
  end
end
