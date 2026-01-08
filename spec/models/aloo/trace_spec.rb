# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::Trace do
  subject(:trace) { build(:aloo_trace) }

  describe 'concerns' do
    it 'includes AccountScoped' do
      expect(described_class.ancestors).to include(Aloo::AccountScoped)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant').optional }
    it { is_expected.to belong_to(:conversation).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:trace_type).in_array(described_class::TRACE_TYPES) }
  end

  describe 'callbacks' do
    describe 'before_validation' do
      it 'truncates long error messages' do
        long_message = 'A' * 500
        trace = build(:aloo_trace, error_message: long_message)

        trace.valid?

        expect(trace.error_message.length).to eq(255)
      end

      it 'preserves short error messages' do
        trace = build(:aloo_trace, error_message: 'Short error')

        trace.valid?

        expect(trace.error_message).to eq('Short error')
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      let!(:recent_trace) { create(:aloo_trace, :recent) }
      let!(:old_trace) { create(:aloo_trace, :old) }

      it 'returns traces from last 24 hours' do
        expect(described_class.recent).to include(recent_trace)
        expect(described_class.recent).not_to include(old_trace)
      end
    end

    describe '.failed' do
      let!(:failed_trace) { create(:aloo_trace, :failed) }
      let!(:successful_trace) { create(:aloo_trace, success: true) }

      it 'returns unsuccessful traces' do
        expect(described_class.failed).to include(failed_trace)
        expect(described_class.failed).not_to include(successful_trace)
      end
    end

    describe '.successful' do
      let!(:failed_trace) { create(:aloo_trace, :failed) }
      let!(:successful_trace) { create(:aloo_trace, success: true) }

      it 'returns successful traces' do
        expect(described_class.successful).to include(successful_trace)
        expect(described_class.successful).not_to include(failed_trace)
      end
    end

    describe '.by_type' do
      let!(:agent_trace) { create(:aloo_trace, :agent_call) }
      let!(:search_trace) { create(:aloo_trace, :search) }

      it 'filters by trace type' do
        expect(described_class.by_type('agent_call')).to include(agent_trace)
        expect(described_class.by_type('agent_call')).not_to include(search_trace)
      end
    end

    describe '.by_request' do
      let(:request_id) { SecureRandom.uuid }
      let!(:matching_trace) { create(:aloo_trace, request_id: request_id) }
      let!(:other_trace) { create(:aloo_trace) }

      it 'filters by request_id' do
        expect(described_class.by_request(request_id)).to include(matching_trace)
        expect(described_class.by_request(request_id)).not_to include(other_trace)
      end
    end
  end

  describe '.record' do
    let(:account) { create(:account) }

    it 'creates trace with provided attributes' do
      trace = described_class.record(
        trace_type: 'agent_call',
        account: account,
        success: true,
        duration_ms: 500
      )

      expect(trace).to be_persisted
      expect(trace.trace_type).to eq('agent_call')
      expect(trace.account).to eq(account)
    end

    it 'uses request_id from Aloo::Current' do
      Aloo::Current.request_id = 'test-request-id'

      trace = described_class.record(
        trace_type: 'search',
        account: account
      )

      expect(trace.request_id).to eq('test-request-id')
    ensure
      Aloo::Current.reset
    end

    it 'truncates long error messages' do
      long_message = 'Error: ' + ('x' * 500)

      trace = described_class.record(
        trace_type: 'agent_call',
        account: account,
        error_message: long_message
      )

      expect(trace.error_message.length).to eq(255)
    end
  end

  describe '.record_with_timing' do
    let(:account) { create(:account) }

    it 'measures duration of block' do
      described_class.record_with_timing(
        trace_type: 'agent_call',
        account: account
      ) do
        sleep(0.01)
        'result'
      end

      trace = described_class.last
      expect(trace.duration_ms).to be >= 10
    end

    it 'records success on normal completion' do
      described_class.record_with_timing(
        trace_type: 'search',
        account: account
      ) { 'result' }

      trace = described_class.last
      expect(trace.success).to be true
      expect(trace.error_message).to be_nil
    end

    it 'records failure on exception' do
      expect do
        described_class.record_with_timing(
          trace_type: 'agent_call',
          account: account
        ) { raise StandardError, 'Something broke' }
      end.to raise_error(StandardError)

      trace = described_class.last
      expect(trace.success).to be false
      expect(trace.error_message).to eq('Something broke')
    end

    it 're-raises exceptions' do
      expect do
        described_class.record_with_timing(
          trace_type: 'agent_call',
          account: account
        ) { raise ArgumentError, 'Bad argument' }
      end.to raise_error(ArgumentError, 'Bad argument')
    end

    it 'returns block result' do
      result = described_class.record_with_timing(
        trace_type: 'embedding',
        account: account
      ) { 'computed value' }

      expect(result).to eq('computed value')
    end
  end

  describe '#duration_seconds' do
    it 'converts duration_ms to seconds' do
      trace = build(:aloo_trace, duration_ms: 1500)
      expect(trace.duration_seconds).to eq(1.5)
    end

    it 'returns nil when duration_ms is nil' do
      trace = build(:aloo_trace, duration_ms: nil)
      expect(trace.duration_seconds).to be_nil
    end
  end

  describe '#total_tokens' do
    it 'sums input and output tokens' do
      trace = build(:aloo_trace, input_tokens: 500, output_tokens: 200)
      expect(trace.total_tokens).to eq(700)
    end

    it 'handles nil tokens' do
      trace = build(:aloo_trace, input_tokens: nil, output_tokens: nil)
      expect(trace.total_tokens).to eq(0)
    end
  end

  describe '#estimated_cost' do
    it 'calculates approximate cost based on tokens' do
      trace = build(:aloo_trace, input_tokens: 1_000_000, output_tokens: 1_000_000)

      # input: 1M * 0.15 / 1M = $0.15
      # output: 1M * 0.60 / 1M = $0.60
      # total: $0.75
      expect(trace.estimated_cost).to eq(0.75)
    end

    it 'returns 0 when tokens are nil' do
      trace = build(:aloo_trace, input_tokens: nil, output_tokens: nil)
      expect(trace.estimated_cost).to eq(0)
    end

    it 'returns 0 when input_tokens is nil' do
      trace = build(:aloo_trace, input_tokens: nil, output_tokens: 100)
      expect(trace.estimated_cost).to eq(0)
    end
  end
end
