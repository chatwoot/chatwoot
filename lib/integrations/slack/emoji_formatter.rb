# frozen_string_literal: true

class Integrations::Slack::EmojiFormatter
  def self.format(text)
    return text if text.blank?

    text.gsub(/:([a-zA-Z0-9_+-]+):/) do |match|
      short_code = Regexp.last_match(1)
      # gemoji exposes find_by_alias; Rails/DynamicFindBy is a false positive because Emoji is not an ActiveRecord model.
      # rubocop:disable Rails/DynamicFindBy
      emoji = Emoji.find_by_alias(short_code)
      # rubocop:enable Rails/DynamicFindBy
      emoji ? emoji.raw : match
    end
  end
end
