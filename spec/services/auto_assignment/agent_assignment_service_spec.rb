require 'rails_helper'

RSpec.describe AutoAssignment::AgentAssignmentService do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let!(:inbox_members) { create_list(:inbox_member, 5, inbox: inbox) }
  let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:online_users) do
    {
      inbox_members[0].user_id.to_s => 'busy',
      inbox_members[1].user_id.to_s => 'busy',
      inbox_members[2].user_id.to_s => 'busy',
      inbox_members[3].user_id.to_s => 'online',
      inbox_members[4].user_id.to_s => 'online'
    }
  end

  before do
    inbox_members.each { |inbox_member| create(:account_user, account: account, user: inbox_member.user) }
    allow(OnlineStatusTracker).to receive(:get_available_users).and_return(online_users)
  end

  describe '#perform' do
    it 'will assign an online agent to the conversation' do
      expect(conversation.reload.assignee).to be_nil
      described_class.new(conversation: conversation, allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).perform
      expect(conversation.reload.assignee).not_to be_nil
    end
  end

  describe '#find_assignee' do
    it 'will return an online agent from the allowed agent ids in roud robin' do
      expect(described_class.new(conversation: conversation,
                                 allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).find_assignee).to eq(inbox_members[3].user)
      expect(described_class.new(conversation: conversation,
                                 allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).find_assignee).to eq(inbox_members[4].user)
    end
  end

  describe 'WhatsApp group creation' do
    let(:agent) { inbox_members[3].user }
    let(:contact) { conversation.contact }

    context 'when assignment_type is group and both have phone numbers' do
      before do
        inbox.update!(auto_assignment_config: { 'assignment_type' => 'group' })
        agent.update!(phone_number: '+1234567890')
        contact.update!(phone_number: '+9876543210')
      end

      it 'enqueues WhatsApp group creation job after assignment' do
        expect(Whatsapp::CreateGroupJob).to receive(:perform_later).with(conversation.id)
        described_class.new(conversation: conversation, allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).perform
      end
    end

    context 'when assignment_type is individual' do
      before do
        inbox.update!(auto_assignment_config: { 'assignment_type' => 'individual' })
        agent.update!(phone_number: '+1234567890')
        contact.update!(phone_number: '+9876543210')
      end

      it 'does not enqueue group creation job' do
        expect(Whatsapp::CreateGroupJob).not_to receive(:perform_later)
        described_class.new(conversation: conversation, allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).perform
      end
    end

    context 'when agent does not have phone number' do
      before do
        inbox.update!(auto_assignment_config: { 'assignment_type' => 'group' })
        agent.update!(phone_number: nil)
        contact.update!(phone_number: '+9876543210')
      end

      it 'does not enqueue group creation job' do
        expect(Whatsapp::CreateGroupJob).not_to receive(:perform_later)
        described_class.new(conversation: conversation, allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).perform
      end
    end

    context 'when contact does not have phone number' do
      before do
        inbox.update!(auto_assignment_config: { 'assignment_type' => 'group' })
        agent.update!(phone_number: '+1234567890')
        contact.update!(phone_number: nil)
      end

      it 'does not enqueue group creation job' do
        expect(Whatsapp::CreateGroupJob).not_to receive(:perform_later)
        described_class.new(conversation: conversation, allowed_agent_ids: inbox_members.map(&:user_id).map(&:to_s)).perform
      end
    end
  end
end
