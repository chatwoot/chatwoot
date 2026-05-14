require 'rails_helper'

RSpec.describe Onboarding::HelpCenterGenerationStatus do
  let(:account) { create(:account, custom_attributes: {}) }
  let(:generation_id) { 'generation-123' }

  describe '.create!' do
    it 'stores pending help center generation state under onboarding' do
      described_class.create!(account, generation_id)

      expect(described_class.current(account.reload)).to eq(
        'id' => generation_id,
        'status' => 'pending'
      )
    end
  end

  describe '.mark_skipped!' do
    it 'stores skipped status and reason' do
      described_class.create!(account, generation_id)
      described_class.mark_skipped!(account, generation_id, reason: 'no website url')

      expect(described_class.current(account.reload)).to eq(
        'id' => generation_id,
        'status' => 'skipped',
        'skip_reason' => 'no website url'
      )
    end
  end

  describe '.mark_completed!' do
    it 'marks the current generation as completed' do
      described_class.create!(account, generation_id)

      expect(described_class.mark_completed!(account, generation_id)).to be(true)
      expect(described_class.current(account.reload)).to eq(
        'id' => generation_id,
        'status' => 'completed'
      )
    end

    it 'does not overwrite a newer generation' do
      described_class.create!(account, 'newer-generation')

      expect(described_class.mark_completed!(account, generation_id)).to be(false)
      expect(described_class.current(account.reload)).to eq(
        'id' => 'newer-generation',
        'status' => 'pending'
      )
    end

    it 'does not create completed state when no current generation exists' do
      expect(described_class.mark_completed!(account, generation_id)).to be(false)
      expect(described_class.current(account.reload)).to be_nil
    end
  end
end
