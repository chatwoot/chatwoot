# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Inbox do
  # let!(:channel) { create(:channel_widget) }
  let!(:inbox) { create(:inbox) }

  describe 'member_ids_with_assignment_capacity' do
    let!(:inbox_member_1) { create(:inbox_member, inbox: inbox) }
    let!(:inbox_member_2) { create(:inbox_member, inbox: inbox) }
    let!(:inbox_member_3) { create(:inbox_member, inbox: inbox) }
    let!(:inbox_member_4) { create(:inbox_member, inbox: inbox) }

    before do
      create(:conversation, inbox: inbox, assignee: inbox_member_1.user)
      # to test conversations in other inboxes won't impact
      create_list(:conversation, 3, assignee: inbox_member_1.user)
      create_list(:conversation, 2, inbox: inbox, assignee: inbox_member_2.user)
      create_list(:conversation, 3, inbox: inbox, assignee: inbox_member_3.user)
    end

    it 'validated max_assignment_limit' do
      account = create(:account)
      expect(build(:inbox, account: account, auto_assignment_config: { max_assignment_limit: 0 })).not_to be_valid
      expect(build(:inbox, account: account, auto_assignment_config: {})).to be_valid
      expect(build(:inbox, account: account, auto_assignment_config: { max_assignment_limit: 1 })).to be_valid
    end

    it 'returns member ids with assignment capacity with inbox max_assignment_limit is configured' do
      # agent 1 has 1 conversations, agent 2 has 2 conversations, agent 3 has 3 conversations and agent 4 with none
      inbox.update(auto_assignment_config: { max_assignment_limit: 2 })
      expect(inbox.member_ids_with_assignment_capacity).to contain_exactly(inbox_member_1.user_id, inbox_member_4.user_id)
    end

    it 'returns all member ids when inbox max_assignment_limit is not configured' do
      expect(inbox.member_ids_with_assignment_capacity).to eq(inbox.members.ids)
    end
  end

  describe 'audit log' do
    context 'when inbox is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'create').count).to eq(1)
      end
    end

    context 'when inbox is updated' do
      it 'has associated audit log created' do
        inbox.update(name: 'Updated Inbox')
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update').count).to eq(1)
      end
    end

    context 'when channel is updated' do
      it 'has associated audit log created' do
        previous_color = inbox.channel.widget_color
        new_color = '#ff0000'
        inbox.channel.update(widget_color: new_color)

        # check if channel update creates an audit log against inbox
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update').count).to eq(1)
        # Check for the specific widget_color update in the audit log
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update',
                                    audited_changes: { 'widget_color' => [previous_color, new_color] }).count).to eq(1)
      end
    end

    context 'when inbox is deleted' do
      it 'has associated audit log created' do
        inbox.destroy!
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'destroy').count).to eq(1)
      end
    end
  end

  describe 'audit log with twilio channel' do
    # reset the table audited only once before all the tests in this block
    before do
      Audited::Audit.delete_all
    end

    let!(:channel) { create(:channel_twilio_sms) }
    let!(:inbox) { create(:inbox, channel: channel) }

    context 'when inbox is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'create').count).to eq(1)
      end
    end

    context 'when inbox is updated' do
      it 'has associated audit log created' do
        inbox.update(name: 'Updated Inbox')
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update').count).to eq(1)
      end
    end

    context 'when channel is updated' do
      it 'has associated audit log created' do
        previous_number = inbox.channel.phone_number
        new_number = '31415926535'
        inbox.channel.update(phone_number: new_number)

        # check if channel update creates an audit log against inbox
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update').count).to eq(1)
        # Check for the specific widget_color update in the audit log
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'update',
                                    audited_changes: { 'phone_number' => [previous_number, new_number] }).count).to eq(1)
      end
    end

    context 'when inbox is deleted' do
      it 'has associated audit log created' do
        inbox.destroy!
        expect(Audited::Audit.where(auditable_type: 'Inbox', action: 'destroy').count).to eq(1)
      end
    end
  end
end
