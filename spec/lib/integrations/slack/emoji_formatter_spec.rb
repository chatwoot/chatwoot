require 'rails_helper'

describe Integrations::Slack::EmojiFormatter do
  describe '.format' do
    it 'replaces emoji shortcodes with unicode characters' do
      expect(described_class.format('Hello :smile:')).to eq('Hello 😄')
      expect(described_class.format('Good job :+1:')).to eq('Good job 👍')
      expect(described_class.format('Unknown :unknown_emoji:')).to eq('Unknown :unknown_emoji:')
    end

    it 'handles nil or empty text' do
      expect(described_class.format(nil)).to be_nil
      expect(described_class.format('')).to eq('')
    end

    it 'replaces multiple emojis' do
      expect(described_class.format(':smile: :+1:')).to eq('😄 👍')
    end
  end
end
