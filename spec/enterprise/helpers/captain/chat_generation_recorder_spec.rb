require 'rails_helper'

RSpec.describe Captain::ChatGenerationRecorder do
  subject(:recorder) { Class.new { include Captain::ChatGenerationRecorder }.new }

  let(:run) { instance_double(CopilotRun) }

  describe '#record_generation_cost' do
    it 'records the provider-reported cost for an assistant message' do
      cost = instance_double(RubyLLM::Cost, total: BigDecimal('0.0123'))
      message = instance_double(RubyLLM::Message, role: :assistant, cost: cost)

      expect(run).to receive(:record_cost!).with(BigDecimal('0.0123'))

      recorder.send(:record_generation_cost, run, message)
    end

    it 'marks the total incomplete when the message cost is unavailable' do
      message = instance_double(RubyLLM::Message, role: :assistant)
      allow(message).to receive(:cost).and_raise(RubyLLM::ModelRegistryError, 'pricing unavailable')

      expect(run).to receive(:record_cost!).with(nil)

      recorder.send(:record_generation_cost, run, message)
    end
  end
end
