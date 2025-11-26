require 'rails_helper'

RSpec.describe Captain::Copilot::ResponseJob, type: :job do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }
  let(:conversation_id) { 123 }
  let(:message) { { 'content' => 'Test message' } }

  describe '#perform' do
    let(:chat_service) { instance_double(Captain::Copilot::ChatService) }

    before do
      allow(Captain::Copilot::ChatService).to receive(:new).with(
        assistant,
        user_id: user.id,
        copilot_thread_id: copilot_thread.id,
        conversation_id: conversation_id
      ).and_return(chat_service)
      # When copilot_thread_id is present, message is already in previous_history
      # so nil is passed to avoid duplicate
      allow(chat_service).to receive(:generate_response).with(nil)
    end

    it 'initializes ChatService with correct parameters and calls generate_response' do
      expect(Captain::Copilot::ChatService).to receive(:new).with(
        assistant,
        user_id: user.id,
        copilot_thread_id: copilot_thread.id,
        conversation_id: conversation_id
      )
      # Message is already persisted in copilot_thread.previous_history,
      # so we pass nil to prevent duplicate user messages
      expect(chat_service).to receive(:generate_response).with(nil)
      described_class.perform_now(
        assistant: assistant,
        conversation_id: conversation_id,
        user_id: user.id,
        copilot_thread_id: copilot_thread.id,
        message: message
      )
    end
  end
end
