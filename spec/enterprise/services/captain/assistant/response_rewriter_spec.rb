# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Assistant::ResponseRewriter do
  describe '#install_instrumentation' do
    it 'preserves Copilot attribution for response rewrite traces' do
      assistant = instance_double(Captain::Assistant)
      attribute_provider = instance_double(Captain::Assistant::InstrumentationAttributeProvider)
      runner = instance_double(Agents::AgentRunner)
      tracer = instance_double(OpenTelemetry::Trace::Tracer)
      service = described_class.new(
        assistant: assistant,
        attribute_provider: attribute_provider,
        trace_config: {
          name: 'llm.captain.copilot',
          tags: ['copilot'],
          feature_name: 'copilot'
        }
      )

      allow(ChatwootApp).to receive(:otel_enabled?).and_return(true)
      allow(OpentelemetryConfig).to receive(:tracer).and_return(tracer)

      expect(Agents::Instrumentation).to receive(:install).with(
        runner,
        tracer: tracer,
        trace_name: 'llm.captain.copilot.rewrite',
        span_attributes: {
          'langfuse.trace.tags' => '["copilot","channel_limit_rewrite"]',
          'langfuse.trace.metadata.feature_name' => 'copilot',
          'langfuse.observation.metadata.feature_name' => 'copilot',
          'langfuse.trace.metadata.credit_used' => 'false'
        },
        attribute_provider: attribute_provider
      )

      service.send(:install_instrumentation, runner)
    end
  end
end
