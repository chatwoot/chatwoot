require 'rails_helper'

RSpec.describe Captain::Copilot::ChatService do
  let(:account) { create(:account, custom_attributes: { plan_name: 'startups' }) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:captain_inbox_association) { create(:captain_inbox, captain_assistant: assistant, inbox: inbox) }

  let(:mock_captain_agent) { instance_double(Captain::Agent) }
  let(:mock_captain_tool) { instance_double(Captain::Tool) }
  let(:mock_openai_client) { instance_double(OpenAI::Client) }

  describe '#execute' do
    before do
      create(:installation_config) { create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key') }
      allow(OpenAI::Client).to receive(:new).and_return(mock_openai_client)
      allow(mock_openai_client).to receive(:chat).and_return({ choices: [{ message: { content: '{ "result": "Hey" }' } }] }.with_indifferent_access)

      allow(Captain::Agent).to receive(:new).and_return(mock_captain_agent)
      allow(mock_captain_agent).to receive(:execute).and_return(true)
      allow(mock_captain_agent).to receive(:register_tool).and_return(true)

      allow(Captain::Tool).to receive(:new).and_return(mock_captain_tool)
      allow(mock_captain_tool).to receive(:register_method).and_return(true)

      allow(account).to receive(:increment_response_usage).and_return(true)
    end

    it 'increments usage' do
      described_class.new(assistant, { previous_messages: ['Hello'], conversation_history: 'Hi' }).generate_response('Hey')
      expect(account).to have_received(:increment_response_usage).once
    end
  end
end
