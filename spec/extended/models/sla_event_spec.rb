require 'rails_helper'

RSpec.describe SlaEvent, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:applied_sla) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:sla_policy) }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'push_event_data' do
    it 'returns the correct hash' do
      sla_event = create(:sla_event)
      expect(sla_event.push_event_data).to eq(
        {
          id: sla_event.id,
          event_type: 'frt',
          meta: sla_event.meta,
          created_at: sla_event.created_at.to_i,
          updated_at: sla_event.updated_at.to_i
        }
      )
    end
  end

  describe 'validates_factory' do
    it 'creates valid sla event object' do
      sla_event = create(:sla_event)
      expect(sla_event.event_type).to eq 'frt'
    end
  end

  describe 'backfilling ids' do
    it 'automatically backfills account_id, inbox_id, and sla_id upon creation' do
      sla_event = create(:sla_event)

      expect(sla_event.account_id).to eq sla_event.conversation.account_id
      expect(sla_event.inbox_id).to eq sla_event.conversation.inbox_id
      expect(sla_event.sla_policy_id).to eq sla_event.applied_sla.sla_policy_id
    end
  end

  describe 'create notifications' do
    # create account, user and inbox
    let!(:account) { create(:account) }
    let!(:assignee) { create(:user, account: account) }
    let!(:participant) { create(:user, account: account) }
    let!(:admin) { create(:user, account: account, role: :administrator) }
    let!(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, inbox: inbox, assignee: assignee, account: account) }
    let(:sla_policy) { create(:sla_policy, account: conversation.account) }
    let(:sla_event) { create(:sla_event, event_type: 'frt', conversation: conversation, sla_policy: sla_policy) }

    before do
      # to ensure notifications are not sent to other users
      create(:user, account: account)
      create(:inbox_member, inbox: inbox, user: participant)
      create(:conversation_participant, conversation: conversation, user: participant)
    end

    it 'creates notifications for conversation participants, admins, and assignee' do
      sla_event

      expect(Notification.count).to eq(3)
      # check if notification type is sla_missed_first_response
      expect(Notification.where(notification_type: 'sla_missed_first_response').count).to eq(3)
      # Check if notification is created for the assignee
      expect(Notification.where(user_id: assignee.id).count).to eq(1)
      # Check if notification is created for the account admin
      expect(Notification.where(user_id: admin.id).count).to eq(1)
      # Check if notification is created for participant
      expect(Notification.where(user_id: participant.id).count).to eq(1)
    end
  end
end
