module Integrations::Slack::EmojiConverter
  EMOJI_SHORTCODE_PATTERN = /:([a-zA-Z0-9_+-]+):/

  def self.convert_slack_emoji(text)
    return text if text.blank?

    text.gsub(EMOJI_SHORTCODE_PATTERN) do |match|
      shortcode = Regexp.last_match(1)
      emoji = find_emoji(shortcode)
      emoji ? emoji.raw : match
    end
  end

  def self.find_emoji(shortcode)
    Emoji.find_by_alias(shortcode) || Emoji.find_by_alias(shortcode.tr('-', '_'))
  end
end
