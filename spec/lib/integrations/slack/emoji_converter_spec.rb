require 'rails_helper'

describe Integrations::Slack::EmojiConverter do
  describe '.convert_slack_emoji' do
    context 'when text is blank' do
      it 'returns the original text for nil' do
        expect(described_class.convert_slack_emoji(nil)).to be_nil
      end

      it 'returns the original text for empty string' do
        expect(described_class.convert_slack_emoji('')).to eq('')
      end
    end

    context 'when text contains no emoji shortcodes' do
      it 'returns the original text unchanged' do
        text = 'Hello, this is a regular message without emojis.'
        expect(described_class.convert_slack_emoji(text)).to eq(text)
      end

      it 'handles text with colons that are not emoji shortcodes' do
        text = 'Time is 10:30 and ratio is 1:2'
        expect(described_class.convert_slack_emoji(text)).to eq(text)
      end
    end

    context 'when text contains valid emoji shortcodes' do
      it 'converts :smile: to the smile emoji' do
        text = 'Hello :smile:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('😄')
        expect(result).not_to include(':smile:')
      end

      it 'converts :thumbsup: to the thumbs up emoji' do
        text = 'Great job :thumbsup:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('👍')
        expect(result).not_to include(':thumbsup:')
      end

      it 'converts :heart: to the heart emoji' do
        text = 'I :heart: this'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('❤️')
        expect(result).not_to include(':heart:')
      end

      it 'converts multiple emoji shortcodes in the same text' do
        text = ':smile: Hello :thumbsup: World :heart:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('😄')
        expect(result).to include('👍')
        expect(result).to include('❤️')
      end

      it 'handles emoji shortcodes with underscores' do
        text = ':slightly_smiling_face:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('🙂')
      end

      it 'handles emoji shortcodes with plus signs' do
        text = ':+1:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('👍')
      end
    end

    context 'when text contains invalid emoji shortcodes' do
      it 'leaves unknown shortcodes unchanged' do
        text = 'Hello :unknown_emoji_xyz:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to eq(text)
      end

      it 'handles mixed valid and invalid shortcodes' do
        text = ':smile: and :nonexistent_emoji:'
        result = described_class.convert_slack_emoji(text)
        expect(result).to include('😄')
        expect(result).to include(':nonexistent_emoji:')
      end
    end

    context 'when shortcodes use hyphens instead of underscores' do
      it 'converts shortcodes with hyphens by trying underscore variant' do
        # Some Slack clients use hyphens, but gemoji uses underscores
        text = ':slightly-smiling-face:'
        result = described_class.convert_slack_emoji(text)
        # Should convert because we try the underscore variant
        expect(result).to include('🙂')
      end
    end
  end

  describe '.find_emoji' do
    it 'finds emoji by exact alias' do
      emoji = described_class.find_emoji('smile')
      expect(emoji).not_to be_nil
      expect(emoji.raw).to eq('😄')
    end

    it 'finds emoji when shortcode has hyphens by converting to underscores' do
      emoji = described_class.find_emoji('slightly-smiling-face')
      expect(emoji).not_to be_nil
      expect(emoji.raw).to eq('🙂')
    end

    it 'returns nil for unknown shortcode' do
      emoji = described_class.find_emoji('this_emoji_does_not_exist_xyz')
      expect(emoji).to be_nil
    end

    it 'handles numeric aliases like +1' do
      emoji = described_class.find_emoji('+1')
      expect(emoji).not_to be_nil
      expect(emoji.raw).to eq('👍')
    end
  end

  describe 'EMOJI_SHORTCODE_PATTERN' do
    let(:pattern) { Integrations::Slack::EmojiConverter::EMOJI_SHORTCODE_PATTERN }

    it 'matches simple shortcodes' do
      expect(pattern.match?(':smile:')).to be true
    end

    it 'matches shortcodes with underscores' do
      expect(pattern.match?(':thumbs_up:')).to be true
    end

    it 'matches shortcodes with hyphens' do
      expect(pattern.match?(':thumbs-up:')).to be true
    end

    it 'matches shortcodes with numbers' do
      expect(pattern.match?(':+1:')).to be true
    end

    it 'does not match empty shortcodes' do
      expect(pattern.match?('::')).to be false
    end

    it 'does not match single colons' do
      expect(pattern.match?(':')).to be false
    end
  end
end
