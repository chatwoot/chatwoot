require 'rails_helper'

RSpec.describe AgentBots::CsmlJob do
  it 'runs csml processor service' do
    event = 'message.created'
    message = create(:message)
    agent_bot = create(:agent_bot)
    processor = double

    allow(Integrations::Csml::ProcessorService).to receive(:new).and_return(processor)
    allow(processor).to receive(:perform)

    described_class.perform_now(event, agent_bot, message)

    expect(Integrations::Csml::ProcessorService)
      .to have_received(:new)
      .with(event_name: event, agent_bot: agent_bot, event_data: { message: message })
  end
end
