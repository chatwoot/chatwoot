require 'rails_helper'

RSpec.describe ConversationOutcome, type: :model do
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

    it {
      expect(subject).to define_enum_for(:episode_trigger)
        .with_values(described_class::EPISODE_TRIGGERS.index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_prefix(:trigger)
    }
  end

  describe 'validations' do
    it 'allows a handoff without a reason category for unclassified handoffs' do
      outcome = build(:conversation_outcome, handoff_at: Time.current)

      expect(outcome).to be_valid
    end

    it 'rejects an assistant from another account' do
      outcome = build(:conversation_outcome)
      outcome.assistant = create(:captain_assistant, account: create(:account))

      expect(outcome).not_to be_valid
      expect(outcome.errors[:assistant]).to be_present
    end

    it 'rejects a conversation from another account' do
      outcome = build(:conversation_outcome)
      outcome.conversation = create(:conversation, account: create(:account))

      expect(outcome).not_to be_valid
      expect(outcome.errors[:conversation]).to be_present
    end

    it 'rejects an inbox from another account' do
      outcome = build(:conversation_outcome)
      outcome.inbox = create(:inbox, account: create(:account))

      expect(outcome).not_to be_valid
      expect(outcome.errors[:inbox]).to be_present
    end

    it 'allows a later episode on the same conversation' do
      existing = create(:conversation_outcome, started_at: 1.hour.ago, ended_at: 30.minutes.ago)
      second_episode = build(
        :conversation_outcome,
        account: existing.account,
        assistant: existing.assistant,
        conversation: existing.conversation,
        inbox: existing.inbox,
        episode_trigger: 'reopen',
        started_at: 30.minutes.ago
      )

      expect(second_episode).to be_valid
    end

    it 'rejects a duplicate boundary on the same conversation' do
      existing = create(:conversation_outcome, started_at: 1.hour.ago)
      duplicate = build(
        :conversation_outcome,
        account: existing.account,
        assistant: existing.assistant,
        conversation: existing.conversation,
        inbox: existing.inbox,
        started_at: existing.started_at
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:started_at]).to be_present
    end
  end

  it 'builds a valid outcome' do
    expect(build(:conversation_outcome)).to be_valid
  end
end
