# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Llm::Models do
  describe '.credit_multiplier_for' do
    it 'returns the credit multiplier for a known model' do
      expect(described_class.credit_multiplier_for('gpt-4.1')).to eq(3)
      expect(described_class.credit_multiplier_for('gpt-4.1-mini')).to eq(1)
      expect(described_class.credit_multiplier_for('gpt-5.1')).to eq(2)
    end

    it 'returns 1 for an unknown model' do
      expect(described_class.credit_multiplier_for('unknown-model')).to eq(1)
    end

    it 'returns 1 for nil' do
      expect(described_class.credit_multiplier_for(nil)).to eq(1)
    end
  end
end
