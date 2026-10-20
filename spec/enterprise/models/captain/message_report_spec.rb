require 'rails_helper'

RSpec.describe Captain::MessageReport, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:user) }

    it 'resolves the conversation association to the top-level Conversation model' do
      # `Captain::Conversation` exists as a job namespace, so without an explicit
      # class_name the association would resolve to that module instead.
      expect(described_class.reflect_on_association(:conversation).klass).to eq(Conversation)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:report_reason) }
    it { is_expected.to validate_inclusion_of(:report_reason).in_array(described_class::REPORT_REASONS) }
  end

  describe 'callbacks' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:message) { create(:message, account: account, conversation: conversation) }

    it 'derives the account and conversation from the message' do
      report = described_class.create!(message: message, user: create(:user, account: account), report_reason: 'other')

      expect(report.account).to eq(account)
      expect(report.conversation).to eq(conversation)
    end
  end

  describe 'factory' do
    it 'creates a valid message report' do
      expect(build(:captain_message_report)).to be_valid
    end
  end
end
