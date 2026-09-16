# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Captain::Apropos::AgentService do
  describe '#run_agent' do
    it 'installs tracing and passes safe turn context to the runner' do
      account = instance_double(Account)
      trace_input = { role: 'coordinator', task: 'Count conversations', input: { type: 'nilclass' } }
      runtime = instance_double(
        Captain::Apropos::Runtime,
        agent_role: 'coordinator',
        trace_input: trace_input,
        model_history: [],
        model_input: nil,
        run_context: { account_id: 1 },
        langfuse_attributes: { 'langfuse.session.id' => 'session-1' }
      )
      service = described_class.new(account: account, runtime: runtime, instruction: 'Count conversations')
      runner = instance_double(Agents::AgentRunner, on_chat_created: nil)
      result = instance_double(Agents::RunResult)
      agent = instance_double(Agents::Agent)

      allow(Agents::Runner).to receive(:with_agents).with(agent).and_return(runner)
      allow(Captain::Apropos::Instrumentation).to receive(:install_runner).and_return(runner)
      allow(runner).to receive(:run).and_return(result)

      expect(Captain::Apropos::Instrumentation).to receive(:install_runner).with(runner, runtime: runtime, role: 'coordinator')
      expect(runner).to receive(:run).with(
        anything,
        context: {
          apropos: runtime,
          apropos_trace_input: trace_input,
          conversation_history: [],
          session_id: 'session-1'
        },
        max_turns: 20
      )

      expect(service.send(:run_agent, agent)).to eq(result)
    end
  end
end
