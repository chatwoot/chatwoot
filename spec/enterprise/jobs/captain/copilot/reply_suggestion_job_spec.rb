require 'rails_helper'

RSpec.describe Captain::Copilot::ReplySuggestionJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
  let(:service) { instance_double(Captain::Copilot::ReplySuggestionService, generate_response: nil) }

  it 'runs the reply suggestion service' do
    expect(Captain::Copilot::ReplySuggestionService).to receive(:new).with(
      assistant: assistant,
      conversation_id: 123,
      user_id: user.id,
      copilot_thread_id: copilot_thread.id
    ).and_return(service)

    described_class.perform_now(
      assistant: assistant,
      conversation_id: 123,
      user_id: user.id,
      copilot_thread_id: copilot_thread.id
    )

    expect(service).to have_received(:generate_response)
  end
end
