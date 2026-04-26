module Integrations::Slack::EmojiConverter
  EMOJI_SHORTCODE_PATTERN = /:([a-zA-Z0-9_+-]+):/

  # Pattern to match fenced code blocks (```...```) and inline code (`...`)
  # We need to preserve emoji shortcodes inside these
  CODE_BLOCK_PATTERN = /```[\s\S]*?```|`[^`]+`/

  def self.convert_slack_emoji(text)
    return text if text.blank?

    # Extract code blocks and replace with placeholders to preserve them
    code_blocks = []
    preserved_text = text.gsub(CODE_BLOCK_PATTERN) do |match|
      code_blocks << match
      "\x00CODE_BLOCK_#{code_blocks.length - 1}\x00"
    end

    # Convert emoji shortcodes in the non-code portions
    converted_text = preserved_text.gsub(EMOJI_SHORTCODE_PATTERN) do |match|
      shortcode = Regexp.last_match(1)
      emoji = find_emoji(shortcode)
      emoji ? emoji.raw : match
    end

    # Restore the code blocks
    code_blocks.each_with_index do |block, index|
      converted_text = converted_text.gsub("\x00CODE_BLOCK_#{index}\x00", block)
    end

    converted_text
  end

  def self.find_emoji(shortcode)
    # rubocop:disable Rails/DynamicFindBy
    # find_by_alias is a method from the gemoji gem, not an ActiveRecord dynamic finder
    Emoji.find_by_alias(shortcode) || Emoji.find_by_alias(shortcode.tr('-', '_'))
    # rubocop:enable Rails/DynamicFindBy
  end
end
