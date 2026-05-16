require 'rails_helper'

RSpec.describe Onboarding::HelpCenterGenerationState do
  let(:generation_id) { 'generation-123' }
  let(:account_id) { 42 }

  after do
    Redis::Alfred.delete(described_class.key(generation_id))
    Redis::Alfred.delete(described_class.account_pointer_key(account_id))
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
    it 'increments finished and flips status to completed only on the exact final count' do
      described_class.start(generation_id, total: 2)

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 1, completed: false)
      expect(described_class.current(generation_id)).to include('status' => 'generating')

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 2, completed: true)
      expect(described_class.current(generation_id)).to include('status' => 'completed', 'finished' => '2')

      expect(described_class.record_article_finished(generation_id)).to eq(finished: 3, completed: false)
      expect(described_class.current(generation_id)).to include('status' => 'completed')
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

  describe '.mark_active and .superseded?' do
    it 'returns false when no pointer is set' do
      expect(described_class.superseded?(generation_id, account_id: account_id)).to be(false)
    end

    it 'returns false when the pointer matches the generation id' do
      described_class.mark_active(generation_id, account_id: account_id)
      expect(described_class.superseded?(generation_id, account_id: account_id)).to be(false)
    end

    it 'returns true when a newer generation has overwritten the pointer' do
      described_class.mark_active(generation_id, account_id: account_id)
      described_class.mark_active('newer-generation', account_id: account_id)
      expect(described_class.superseded?(generation_id, account_id: account_id)).to be(true)
    end
  end
end
