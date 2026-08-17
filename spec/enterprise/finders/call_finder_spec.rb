require 'rails_helper'

describe CallFinder do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before { create(:inbox_member, user: agent, inbox: inbox) }

  def perform(user, params = {})
    Current.account = account
    Current.account_user = account.account_users.find_by(user_id: user.id)
    described_class.new(user, account, params).perform
  end

  describe 'visibility' do
    let!(:agent_call) do
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, accepted_by_agent: agent)
    end
    let!(:other_call) do
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, accepted_by_agent: admin)
    end

    it 'lets an administrator see every call in the account' do
      result = perform(admin)
      expect(result[:count]).to eq(2)
      expect(result[:calls].map(&:id)).to contain_exactly(agent_call.id, other_call.id)
    end

    it 'lets an agent with report_manage see every call in the account' do
      report_manager = create(:user, account: account, role: :agent)
      custom_role = create(:custom_role, account: account, permissions: ['report_manage'])
      account.account_users.find_by(user_id: report_manager.id).update!(custom_role: custom_role)

      result = perform(report_manager)
      expect(result[:calls].map(&:id)).to contain_exactly(agent_call.id, other_call.id)
    end

    it 'limits a regular agent to calls they accepted in accessible conversations' do
      result = perform(agent)
      expect(result[:calls].map(&:id)).to contain_exactly(agent_call.id)
    end

    it 'limits a custom-role agent without report_manage to their own accepted calls' do
      scoped_agent = create(:user, account: account, role: :agent)
      custom_role = create(:custom_role, account: account, permissions: ['conversation_manage'])
      account.account_users.find_by(user_id: scoped_agent.id).update!(custom_role: custom_role)
      create(:inbox_member, user: scoped_agent, inbox: inbox)
      scoped_call = create(:call, account: account, inbox: inbox, conversation: conversation,
                                  contact: conversation.contact, accepted_by_agent: scoped_agent)

      result = perform(scoped_agent)
      expect(result[:calls].map(&:id)).to contain_exactly(scoped_call.id)
    end
  end

  describe 'filters' do
    let(:inbox2) { create(:inbox, account: account) }
    let(:conversation2) { create(:conversation, account: account, inbox: inbox2) }
    let(:agent2) { create(:user, account: account, role: :agent) }
    let!(:ringing) do
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    status: 'ringing', direction: :incoming, accepted_by_agent: agent)
    end
    let!(:in_progress) do
      create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                    status: 'in_progress', direction: :incoming, accepted_by_agent: agent)
    end
    let!(:completed) do
      create(:call, account: account, inbox: inbox2, conversation: conversation2, contact: conversation2.contact,
                    status: 'completed', direction: :outgoing, accepted_by_agent: agent2, created_at: 10.days.ago)
    end

    it 'filters by status using the display value' do
      expect(perform(admin, status: 'in-progress')[:calls].map(&:id)).to contain_exactly(in_progress.id)
    end

    it 'filters by direction using the display label' do
      expect(perform(admin, direction: 'outbound')[:calls].map(&:id)).to contain_exactly(completed.id)
    end

    it 'filters by inbox' do
      expect(perform(admin, inbox_id: inbox2.id)[:calls].map(&:id)).to contain_exactly(completed.id)
    end

    it 'filters by agent' do
      expect(perform(admin, agent_id: agent2.id)[:calls].map(&:id)).to contain_exactly(completed.id)
    end

    it 'filters by created_at date range' do
      params = { since: 2.days.ago.to_i.to_s, until: 1.hour.from_now.to_i.to_s }
      expect(perform(admin, params)[:calls].map(&:id)).to contain_exactly(ringing.id, in_progress.id)
    end
  end

  describe 'account scoping' do
    it 'never returns calls from another account' do
      other_account = create(:account)
      other_conversation = create(:conversation, account: other_account)
      create(:call, account: other_account, inbox: other_conversation.inbox, conversation: other_conversation,
                    contact: other_conversation.contact)

      expect(perform(admin)[:count]).to eq(0)
    end
  end
end
