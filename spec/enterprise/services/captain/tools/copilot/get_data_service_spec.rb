require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetDataService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  def description_for(user)
    thread = create(:captain_copilot_thread, account: account, user: user, assistant: assistant)
    message = create(:captain_copilot_message, account: account, copilot_thread: thread)
    run = CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message)
    described_class.new(assistant, user: user, run: run, lease_token: nil).description
  end

  it 'lists only the resources the user may read' do
    admin_description = description_for(create(:user, :administrator, account: account))
    agent_description = description_for(create(:user, account: account))

    expect(admin_description).to include('- campaigns (administrators)', '- conversations')
    expect(agent_description).to include('- conversations', '- messages')
    expect(agent_description).not_to include('campaigns')
  end
end
