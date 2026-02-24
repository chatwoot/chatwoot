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
  end
end
