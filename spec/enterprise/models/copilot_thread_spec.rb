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

  describe '#saved_set' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user) }
    let!(:collection) do
      CopilotRun::Collection.create!(account: account, user: user, copilot_thread: copilot_thread, status: :completed,
                                     context: { resource: 'conversations', selected_ids: [1], as_of: Time.current.iso8601 })
    end

    it 'finds only the kinds of run asked for' do
      expect(copilot_thread.saved_set(collection.id)).to eq(collection)
      expect { copilot_thread.saved_set(collection.id, types: [CopilotRun::Review]) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
