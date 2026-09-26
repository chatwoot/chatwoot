# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Tools::RunGuard do
  let(:state) { {} }
  let(:guard) { described_class.new(state) }

  describe '#register_call' do
    it 'allows calls while the run stays within its budget' do
      results = Array.new(described_class::MAX_TOOL_CALLS_PER_RUN) { |index| guard.register_call('faq_lookup', { query: "question #{index}" }) }

      expect(results).to all(eq(:allowed))
      expect(guard.total_calls).to eq(described_class::MAX_TOOL_CALLS_PER_RUN)
    end

    it 'reports an exhausted budget once the run exceeds the tool call limit' do
      described_class::MAX_TOOL_CALLS_PER_RUN.times { |index| guard.register_call('faq_lookup', { query: "question #{index}" }) }

      expect(guard.register_call('faq_lookup', { query: 'one more' })).to eq(:exhausted)
      expect(guard.total_calls).to eq(described_class::MAX_TOOL_CALLS_PER_RUN + 1)
    end

    it 'reports repeated calls only after the identical call limit' do
      results = Array.new(described_class::MAX_IDENTICAL_TOOL_CALLS + 1) { guard.register_call('add_label', { label_name: 'sales' }) }

      expect(results.first(described_class::MAX_IDENTICAL_TOOL_CALLS)).to all(eq(:allowed))
      expect(results.last).to eq(:repeated)
    end

    it 'treats arguments that only differ in case and padding as the same call' do
      described_class::MAX_IDENTICAL_TOOL_CALLS.times { guard.register_call('add_label', { label_name: 'Sales' }) }

      expect(guard.register_call('add_label', { label_name: '  sales ' })).to eq(:repeated)
    end

    it 'counts each tool separately' do
      described_class::MAX_IDENTICAL_TOOL_CALLS.times { guard.register_call('add_label', { label_name: 'sales' }) }

      expect(guard.register_call('update_priority', { label_name: 'sales' })).to eq(:allowed)
    end

    it 'keeps counters inside the run state so concurrent runs stay independent' do
      other_run = described_class.new({})
      described_class::MAX_TOOL_CALLS_PER_RUN.times { guard.register_call('faq_lookup', { query: 'question' }) }

      expect(other_run.register_call('faq_lookup', { query: 'question' })).to eq(:allowed)
      expect(other_run.total_calls).to eq(1)
    end
  end

  describe '#halt' do
    it 'returns a RubyLLM halt that records the reason on the run state' do
      result = guard.halt(described_class::STALE_RUN, 'stopped')

      expect(result).to be_a(RubyLLM::Tool::Halt)
      expect(result.content).to eq('stopped')
      expect(described_class.halt_reason(state)).to eq(described_class::STALE_RUN)
    end
  end

  describe '.halt_reason' do
    it 'returns nil for a run that was never halted' do
      expect(described_class.halt_reason(state)).to be_nil
      expect(described_class.halt_reason(nil)).to be_nil
    end
  end
end
