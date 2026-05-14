require 'rails_helper'

RSpec.describe Onboarding::HelpCenterGenerationCounter do
  let(:generation_id) { 'generation-123' }

  after do
    Redis::Alfred.delete(described_class.key(generation_id))
  end

  describe '.create!' do
    it 'stores total, initializes finished count, and sets a ttl' do
      described_class.create!(generation_id, total: 2)

      Redis::Alfred.with do |conn|
        expect(conn.hget(described_class.key(generation_id), 'total')).to eq('2')
        expect(conn.hget(described_class.key(generation_id), 'finished')).to eq('0')
        expect(conn.ttl(described_class.key(generation_id))).to be_positive
      end
    end
  end

  describe '.record_finished!' do
    it 'increments finished and reports completion only on the final count' do
      described_class.create!(generation_id, total: 2)

      expect(described_class.record_finished!(generation_id)).to eq(finished: 1, completed: false)
      expect(described_class.record_finished!(generation_id)).to eq(finished: 2, completed: true)
      expect(described_class.record_finished!(generation_id)).to eq(finished: 3, completed: false)
    end

    it 'raises Missing when the counter does not exist' do
      expect { described_class.record_finished!(generation_id) }
        .to raise_error(described_class::Missing)
    end
  end
end
