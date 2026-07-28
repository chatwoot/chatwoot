require 'rails_helper'

RSpec.describe Captain::ConversationOutcome, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:conversation).class_name('::Conversation') }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:resolution_type).with_values(autonomous: 0, assisted: 1).with_prefix(:resolution) }
  end

  describe 'validations' do
    subject(:outcome) { build(:captain_conversation_outcome) }

    it { is_expected.to validate_presence_of(:eligible_at) }
    it { is_expected.to validate_numericality_of(:captain_reply_count).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:reopen_count).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:csat_rating).in_range(1..5).allow_nil }

    it 'requires unique conversations per assistant and account' do
      existing = create(:captain_conversation_outcome)
      duplicate = build(
        :captain_conversation_outcome,
        account: existing.account,
        assistant: existing.assistant,
        conversation: existing.conversation,
        inbox: existing.inbox
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:conversation_id]).to be_present
    end

    it 'rejects dimensions from another account' do
      outcome = build(:captain_conversation_outcome, assistant: create(:captain_assistant))

      expect(outcome).not_to be_valid
      expect(outcome.errors[:assistant]).to be_present
    end

    it 'requires the outcome inbox to match the conversation inbox' do
      account = create(:account)
      outcome = build(
        :captain_conversation_outcome,
        account: account,
        assistant: create(:captain_assistant, account: account),
        conversation: create(:conversation, account: account),
        inbox: create(:inbox, account: account)
      )

      expect(outcome).not_to be_valid
      expect(outcome.errors[:inbox]).to be_present
    end
  end

  it 'builds a valid outcome' do
    expect(build(:captain_conversation_outcome)).to be_valid
  end
end
