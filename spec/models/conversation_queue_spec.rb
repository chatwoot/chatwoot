# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConversationQueue do
  describe 'validations' do
    subject { create(:conversation_queue) }

    it { is_expected.to validate_uniqueness_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:inbox_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:account) }
  end

  describe 'scopes' do
    let!(:account) { create(:account) }
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation1) { create(:conversation, inbox: inbox, account: account) }
    let!(:conversation2) { create(:conversation, inbox: inbox, account: account) }

    let!(:queue1) do
      create(:conversation_queue, account: account, inbox: inbox, conversation: conversation1, position: 1, queued_at: 1.hour.ago)
    end

    let!(:queue2) do
      create(:conversation_queue, account: account, inbox: inbox, conversation: conversation2, position: 2, queued_at: 30.minutes.ago)
    end

    describe '.waiting' do
      it 'returns only waiting items ordered by position, then queued_at' do
        expect(described_class.waiting).to eq([queue1, queue2])
      end
    end

    describe '.for_account' do
      it 'filters by account' do
        expect(described_class.for_account(account.id)).to include(queue1, queue2)
      end
    end

    describe '.for_inbox' do
      it 'filters by inbox' do
        expect(described_class.for_inbox(inbox.id)).to include(queue1, queue2)
      end
    end

    describe '.for_priority_group' do
      it 'filters by priority group of the inbox' do
        group = inbox.priority_group
        expect(described_class.for_priority_group(group)).to include(queue1, queue2)
      end

      it 'returns empty when group does not match' do
        other_group = create(:priority_group)
        expect(described_class.for_priority_group(other_group)).to be_empty
      end
    end
  end

  describe 'callbacks' do
    it 'sets position on create' do
      account = create(:account)
      inbox = create(:inbox, account: account)
      conversation = create(:conversation, account: account, inbox: inbox)

      q1 = create(:conversation_queue, account: account, inbox: inbox, conversation: conversation)
      expect(q1.position).to eq(1)

      conversation2 = create(:conversation, account: account, inbox: inbox)
      q2 = create(:conversation_queue, account: account, inbox: inbox, conversation: conversation2)
      expect(q2.position).to eq(2)
    end
  end

  describe '#wait_time_seconds' do
    let(:queue_item) { create(:conversation_queue) }

    it 'returns 0 when not assigned or left' do
      expect(queue_item.wait_time_seconds).to eq(0)
    end

    it 'returns correct wait time when assigned_at is present' do
      queue_item.update(assigned_at: queue_item.queued_at + 120)
      expect(queue_item.wait_time_seconds).to eq(120)
    end

    it 'returns correct wait time when left_at is present' do
      queue_item.update(left_at: queue_item.queued_at + 300)
      expect(queue_item.wait_time_seconds).to eq(300)
    end
  end

  describe '#next_position' do
    let(:account) { create(:account) }
    let(:group) { create(:priority_group) }
    let(:inbox) { create(:inbox, account: account, priority_group: group) }
    let(:conversation) { create(:conversation, inbox: inbox, account: account) }

    it 'returns 1 when no other queues exist' do
      q = build(:conversation_queue, account: account, inbox: inbox, conversation: conversation)
      expect(q.send(:next_position)).to eq(1)
    end

    it 'increments to next position in same priority group' do
      create(:conversation_queue, account: account, inbox: inbox, conversation: conversation, position: 1)
      conversation2 = create(:conversation, account: account, inbox: inbox)
      q2 = build(:conversation_queue, account: account, inbox: inbox, conversation: conversation2)
      expect(q2.send(:next_position)).to eq(2)
    end
  end
end
