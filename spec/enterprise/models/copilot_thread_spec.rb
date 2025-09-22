require 'rails_helper'

RSpec.describe CopilotThread, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to have_many(:copilot_messages).dependent(:destroy_async) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe '#push_event_data' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant, title: 'Test Thread') }

    it 'returns the correct event data' do
      event_data = copilot_thread.push_event_data

      expect(event_data[:id]).to eq(copilot_thread.id)
      expect(event_data[:title]).to eq('Test Thread')
      expect(event_data[:created_at]).to eq(copilot_thread.created_at.to_i)
      expect(event_data[:user]).to eq(user.push_event_data)
      expect(event_data[:account_id]).to eq(account.id)
    end
  end

  describe '#previous_history' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user, assistant: assistant) }

    context 'when there are messages in the thread' do
      before do
        create(:captain_copilot_message, copilot_thread: copilot_thread, message_type: 'user', message: { 'content' => 'User message' })
        create(:captain_copilot_message, copilot_thread: copilot_thread, message_type: 'assistant_thinking', message: { 'content' => 'Thinking...' })
        create(:captain_copilot_message, copilot_thread: copilot_thread, message_type: 'assistant', message: { 'content' => 'Assistant message' })
      end

      it 'returns only user and assistant messages in chronological order' do
        history = copilot_thread.previous_history

        expect(history.length).to eq(2)
        expect(history[0][:role]).to eq('user')
        expect(history[0][:content]).to eq('User message')
        expect(history[1][:role]).to eq('assistant')
        expect(history[1][:content]).to eq('Assistant message')
      end
    end

    context 'when there are no messages in the thread' do
      it 'returns an empty array' do
        expect(copilot_thread.previous_history).to eq([])
      end
    end
  end
end
