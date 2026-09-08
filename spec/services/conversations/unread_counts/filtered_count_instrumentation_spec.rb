require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::FilteredCountInstrumentation do
  let(:new_relic_agent) do
    Class.new do
      def self.record_custom_event(*) end
      def self.record_metric(*) end
    end
  end

  before do
    stub_const('NewRelic::Agent', new_relic_agent)
    allow(new_relic_agent).to receive(:record_custom_event)
    allow(new_relic_agent).to receive(:record_metric)
  end

  describe '.observe' do
    it 'records duration metrics without custom events around successful operations' do
      result = described_class.observe(:counter_perform, account_id: 1, snapshot_scope: :built_in_filter) { 'ok' }

      expect(result).to eq('ok')
      expect(new_relic_agent).not_to have_received(:record_custom_event)
      expect(new_relic_agent).to have_received(:record_metric).with(
        'Custom/Conversations/UnreadCounts/Filtered/counter_perform/duration_ms',
        kind_of(Float)
      )
    end

    it 'records failed operations and re-raises the original error' do
      error = StandardError.new('boom')

      expect do
        described_class.observe(:snapshot_build, account_id: 1) { raise error }
      end.to raise_error(error)
      expect(new_relic_agent).not_to have_received(:record_custom_event)
      expect(new_relic_agent).to have_received(:record_metric).with(
        'Custom/Conversations/UnreadCounts/Filtered/snapshot_build/duration_ms',
        kind_of(Float)
      )
    end
  end

  describe '.increment' do
    it 'records count metrics without custom events for aggregated read-path operations' do
      described_class.increment(:snapshot_state, account_id: 1, snapshot_status: :fresh)

      expect(new_relic_agent).not_to have_received(:record_custom_event)
      expect(new_relic_agent).to have_received(:record_metric).with(
        'Custom/Conversations/UnreadCounts/Filtered/snapshot_state/count',
        1
      )
    end

    it 'keeps custom events for invalidation signals' do
      described_class.increment(:invalidation, account_id: 1, invalidation_scope: :conversation)

      expect(new_relic_agent).to have_received(:record_custom_event).with(
        'FilteredUnreadCounts',
        hash_including(
          account_id: 1,
          invalidation_scope: 'conversation',
          operation: 'invalidation'
        )
      )
      expect(new_relic_agent).to have_received(:record_metric).with(
        'Custom/Conversations/UnreadCounts/Filtered/invalidation/count',
        1
      )
    end

    it 'does not raise when New Relic is unavailable' do
      allow(described_class).to receive(:new_relic_agent).and_return(nil)

      expect { described_class.increment(:snapshot_state, account_id: 1) }.not_to raise_error
    end
  end

  describe '.summarize_request' do
    it 'records one custom event with aggregated request counters' do
      result = described_class.summarize_request(account_id: 1) do
        described_class.increment(:snapshot_state, account_id: 1, snapshot_scope: :built_in_filter, snapshot_status: :fresh)
        described_class.increment(:snapshot_state, account_id: 1, snapshot_scope: :filter, snapshot_status: :missing)
        described_class.increment(:refresh_claim, account_id: 1, snapshot_scope: :filter, claimed: true)
        described_class.increment(:refresh_claim, account_id: 1, snapshot_scope: :filter, claimed: false)
        described_class.increment(:build_lock, account_id: 1, snapshot_scope: :filter, acquired: true)
        described_class.observe(:snapshot_build, account_id: 1, snapshot_scope: :filter) { 'built' }

        'ok'
      end

      expect(result).to eq('ok')
      expect(new_relic_agent).to have_received(:record_custom_event).once.with(
        'FilteredUnreadCounts',
        hash_including(
          account_id: 1,
          build_lock_acquired_count: 1,
          duration_ms: kind_of(Float),
          filter_build_lock_acquired_count: 1,
          filter_refresh_claimed_count: 1,
          filter_refresh_skipped_count: 1,
          filter_snapshot_build_success_count: 1,
          filter_snapshot_count: 1,
          operation: 'request_summary',
          refresh_claimed_count: 1,
          refresh_skipped_count: 1,
          snapshot_build_success_count: 1,
          snapshot_fresh_count: 1,
          snapshot_missing_count: 1,
          snapshot_total_count: 2,
          status: 'success'
        )
      )
      expect(new_relic_agent).to have_received(:record_metric).with(
        'Custom/Conversations/UnreadCounts/Filtered/api_response/duration_ms',
        kind_of(Float)
      )
    end

    it 'records summary errors and re-raises the original error' do
      error = StandardError.new('boom')

      expect do
        described_class.summarize_request(account_id: 1) { raise error }
      end.to raise_error(error)

      expect(new_relic_agent).to have_received(:record_custom_event).with(
        'FilteredUnreadCounts',
        hash_including(
          account_id: 1,
          error_class: 'StandardError',
          operation: 'request_summary',
          status: 'error'
        )
      )
    end
  end
end
