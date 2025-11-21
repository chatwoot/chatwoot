# frozen_string_literal: true

require 'json'

class Integrations::Slack::EmojiFormatter
  EMOJI_MAPPING = JSON.parse(File.read(File.join(__dir__, 'emojis.json'))).freeze

  def self.format(text)
    return text if text.blank?

    text.gsub(/:([a-zA-Z0-9_+-]+):/) do |match|
      short_code = Regexp.last_match(1)
      EMOJI_MAPPING[short_code] || match
    end
  end
end
