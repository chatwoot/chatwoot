require 'rails_helper'

RSpec.describe ConversationParticipant do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it 'ensure account is present' do
      conversation = create(:conversation)
      conversation_participant = build(:conversation_participant, conversation: conversation, account_id: nil)
      conversation_participant.valid?
      expect(conversation_participant.account_id).to eq(conversation.account_id)
    end

    it 'throws error if inbox member does not belongs to account' do
      conversation = create(:conversation)
      user = create(:user, account: conversation.account)
      participant = build(:conversation_participant, user: user, conversation: conversation)
      expect { participant.save! }.to raise_error(ActiveRecord::RecordInvalid)
      expect(participant.errors.messages[:user]).to eq(['must have inbox access'])
    end
  end
end
