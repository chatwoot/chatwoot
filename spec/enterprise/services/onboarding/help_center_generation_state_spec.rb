require 'rails_helper'

RSpec.describe Onboarding::HelpCenterGenerationState do
  let(:generation_id) { 'generation-123' }
  let(:account_id) { 42 }

  after do
    Redis::Alfred.delete(described_class.key(generation_id))
  end

  describe '.start' do
    it 'stores status, total, finished, and sets a ttl' do
      described_class.start(generation_id, total: 2)

      Redis::Alfred.with do |conn|
        expect(conn.hget(described_class.key(generation_id), 'status')).to eq('generating')
        expect(conn.hget(described_class.key(generation_id), 'total')).to eq('2')
        expect(conn.hget(described_class.key(generation_id), 'finished')).to eq('0')
        expect(conn.ttl(described_class.key(generation_id))).to be_positive
      end
    end
  end

  describe '.record_article_finished' do
    it 'increments finished and keeps completed true past the final count' do
      described_class.start(generation_id, total: 2)

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 1, completed: false)
      expect(described_class.current(generation_id)).to include('status' => 'generating')

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 2, completed: true)
      expect(described_class.current(generation_id)).to include('status' => 'completed', 'finished' => '2')

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 3, completed: true)
      expect(described_class.current(generation_id)).to include('status' => 'completed', 'finished' => '3')
    end

    it 'raises Missing when no state exists for the generation' do
      expect { described_class.record_article_finished(generation_id) }
        .to raise_error(described_class::Missing)
    end
  end

  describe '.skip' do
    it 'stores status and reason' do
      described_class.start(generation_id, total: 2)
      described_class.skip(generation_id, reason: 'no website url')

      expect(described_class.current(generation_id)).to include(
        'status' => 'skipped',
        'skip_reason' => 'no website url'
      )
    end
  end

  describe '.current' do
    it 'returns nil when no state exists' do
      expect(described_class.current(generation_id)).to be_nil
    end
  end
end
