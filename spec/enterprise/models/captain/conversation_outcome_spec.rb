require 'rails_helper'

RSpec.describe Captain::ConversationOutcome, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:conversation).class_name('::Conversation') }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:handoff_reason_category)
        .with_values(described_class::HANDOFF_REASON_CATEGORIES.index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_prefix(:handoff_reason)
    }
  end

  describe 'validations' do
    it 'requires a reason category when a handoff is recorded' do
      outcome = build(:captain_conversation_outcome, handoff_at: Time.current)

      expect(outcome).not_to be_valid
      expect(outcome.errors[:handoff_reason_category]).to be_present
    end

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
  end

  it 'builds a valid outcome' do
    expect(build(:captain_conversation_outcome)).to be_valid
  end
end
