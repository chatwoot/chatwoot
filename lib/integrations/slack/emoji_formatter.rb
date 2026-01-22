# frozen_string_literal: true

class Integrations::Slack::EmojiFormatter
  def self.format(text)
    return text if text.blank?

    text.gsub(/:([a-zA-Z0-9_+-]+):/) do |match|
      short_code = Regexp.last_match(1)
      emoji = Emoji.find_by_alias(short_code)
      emoji ? emoji.raw : match
    end
  end
end
