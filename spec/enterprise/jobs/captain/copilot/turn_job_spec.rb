require 'rails_helper'

RSpec.describe Captain::Copilot::TurnJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: user, copilot_thread: thread, copilot_message: message) }
  let(:service) { instance_double(Captain::Copilot::TurnService) }

  before do
    account.enable_features!('copilot_workflows')
    allow(Captain::Copilot::TurnService).to receive(:new).and_return(service)
  end

  it 'marks the reply to a failed turn as failed' do
    allow(service).to receive(:generate_response).and_raise(Captain::Copilot::LimitExceededError, 'You are out of Copilot credits.')

    described_class.perform_now(turn.id)

    expect(turn.reload).to be_failed
    expect(thread.copilot_messages.assistant.last.message).to eq(
      'run_id' => turn.id, 'content' => 'You are out of Copilot credits.', 'status' => 'failed'
    )
  end
end
