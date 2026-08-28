require 'rails_helper'

RSpec.describe Captain::AssistantResponse, type: :model do
  describe 'account validation' do
    it 'uses the assistant account when the account is not set' do
      assistant = create(:captain_assistant)
      assistant_response = build(:captain_assistant_response, assistant: assistant, account: nil)

      expect(assistant_response).to be_valid
      expect(assistant_response.account).to eq(assistant.account)
    end

    it 'rejects an assistant from another account' do
      account = create(:account)
      assistant_response = build(:captain_assistant_response, account: account)

      expect(assistant_response).not_to be_valid
      expect(assistant_response.errors[:assistant]).to include('is invalid')
    end
  end
end
