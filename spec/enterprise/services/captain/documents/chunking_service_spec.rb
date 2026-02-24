require 'rails_helper'

RSpec.describe Captain::Documents::ChunkingService do
  describe '#chunk' do
    it 'returns no chunks for blank content' do
      result = described_class.new('').chunk

      expect(result).to eq([])
    end

    it 'returns ordered chunks with position and token count' do
      content = <<~TEXT
        # Pricing
        Starts at $19 per agent.

        ## Limits
        Includes 100 contacts.

        ## Support
        Email support is available 24/7.
      TEXT

      result = described_class.new(
        content,
        target_tokens: 8,
        min_tokens: 4,
        max_tokens: 10,
        overlap_tokens: 0
      ).chunk

      expect(result.size).to be >= 2
      expect(result.map { |chunk| chunk[:position] }).to eq((0...result.size).to_a)
      expect(result).to all(include(:content, :token_count, :position))
      expect(result).to all(satisfy { |chunk| chunk[:token_count].positive? })
      expect(result.first[:content]).to include('Section: Pricing')
    end

    it 'adds overlap from previous chunk to the next chunk' do
      content = <<~TEXT
        one two three four five six seven eight nine ten

        alpha beta gamma delta epsilon zeta eta theta iota kappa
      TEXT

      result = described_class.new(
        content,
        target_tokens: 5,
        min_tokens: 3,
        max_tokens: 5,
        overlap_tokens: 2
      ).chunk

      expect(result.size).to eq(2)
      expect(result.last[:content]).to include('nine ten')
    end

    it 'removes obvious boilerplate navigation sections before chunking' do
      content = <<~TEXT
        # Account deletion
        You can delete your account from Settings.

        ## Related articles
        - [How to block someone](https://example.com/block)
        - [How to report someone](https://example.com/report)
        - [How to update profile](https://example.com/profile)
      TEXT

      result = described_class.new(
        content,
        target_tokens: 30,
        min_tokens: 10,
        max_tokens: 50,
        overlap_tokens: 0
      ).chunk

      combined_content = result.map { |chunk| chunk[:content] }.join("\n")
      expect(combined_content).to include('You can delete your account from Settings')
      expect(combined_content).not_to include('How to block someone')
      expect(combined_content).not_to include('Related articles')
    end

    it 'removes single-line navigation and language selector blobs before chunking' do
      content = <<~TEXT
        [![Bumble Support Help Center home page](https://support.bumble.com/hc/theming_assets/logo.svg)] [Date](https://bumble.com/en-us/date) [Friends](https://bumble.com/en-us/bff) [Bizz](https://bumble.com/en-us/bizz) [Safety](https://bumble.com/en-us/the-buzz/category/safety) [Dansk](https://support.bumble.com/hc/change_language/da?return_to=%2Fhc%2Fen-us) [Deutsch](https://support.bumble.com/hc/change_language/de?return_to=%2Fhc%2Fen-us) [Espanol](https://support.bumble.com/hc/change_language/es?return_to=%2Fhc%2Fen-us)

        # How to delete my account
        Open Settings and select Delete account.
      TEXT

      result = described_class.new(
        content,
        target_tokens: 30,
        min_tokens: 10,
        max_tokens: 50,
        overlap_tokens: 0
      ).chunk

      combined_content = result.map { |chunk| chunk[:content] }.join("\n")
      expect(combined_content).to include('Open Settings and select Delete account')
      expect(combined_content).not_to include('Help Center home page')
      expect(combined_content).not_to include('change_language')
      expect(combined_content).not_to include('[Date](')
    end
  end
end
