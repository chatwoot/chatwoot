require 'rails_helper'

RSpec.describe 'Keycloak role based policies', type: :policy do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:contact) { create(:contact, account: account) }

  def build_context(user)
    { user: user, account: account, account_user: user.account_users.find_by(account: account) }
  end

  def user_with_roles(*roles)
    user = create(:user, account: account, role: :agent)
    Keycloak::RoleSyncService.new(user: user, keycloak_roles: roles).perform if roles.any?
    user.reload
  end

  def permits?(policy_class, user, record, action)
    Current.account = account
    Current.user = user
    policy_class.new(build_context(user), record).public_send(action)
  end

  after do
    Current.reset
  end

  describe 'ConversationPolicy' do
    it 'denies deletion to a limited agent' do
      expect(permits?(ConversationPolicy, user_with_roles('keycloak:chatwoot_agent_limited'), conversation, :destroy?)).to be(false)
    end

    it 'allows deletion to a manager' do
      expect(permits?(ConversationPolicy, user_with_roles('keycloak:chatwoot_manager'), conversation, :destroy?)).to be(true)
    end

    it 'allows deletion to a keycloak administrator' do
      expect(permits?(ConversationPolicy, user_with_roles('chatwoot_admin'), conversation, :destroy?)).to be(true)
    end

    it 'hides conversations of unassigned inboxes from a limited agent' do
      expect(permits?(ConversationPolicy, user_with_roles('chatwoot_agent_limited'), conversation, :show?)).to be(false)
    end

    it 'shows conversations of every inbox to a manager' do
      expect(permits?(ConversationPolicy, user_with_roles('chatwoot_manager'), conversation, :show?)).to be(true)
    end
  end

  describe 'ContactPolicy' do
    it 'denies export to limited agents and allows it for managers' do
      expect(permits?(ContactPolicy, user_with_roles('chatwoot_agent_limited'), contact, :export?)).to be(false)
      expect(permits?(ContactPolicy, user_with_roles('chatwoot_manager'), contact, :export?)).to be(true)
    end

    it 'denies contact deletion to managers without can_delete_contacts' do
      expect(permits?(ContactPolicy, user_with_roles('chatwoot_manager'), contact, :destroy?)).to be(false)
    end
  end

  describe 'InboxPolicy' do
    it 'denies inbox configuration to non administrators' do
      expect(permits?(InboxPolicy, user_with_roles('chatwoot_manager'), inbox, :update?)).to be(false)
    end

    it 'allows inbox configuration to administrators' do
      expect(permits?(InboxPolicy, user_with_roles('chatwoot_admin'), inbox, :update?)).to be(true)
    end

    it 'scopes inboxes of a limited agent to the assigned ones' do
      limited = user_with_roles('chatwoot_agent_limited')
      Current.account = account
      expect(limited.assigned_inboxes).not_to include(inbox)
      expect(user_with_roles('chatwoot_manager').assigned_inboxes).to include(inbox)
    end
  end

  describe 'AutomationRulePolicy' do
    it 'follows can_manage_automations' do
      expect(permits?(AutomationRulePolicy, user_with_roles('chatwoot_manager'), AutomationRule.new, :index?)).to be(true)
      expect(permits?(AutomationRulePolicy, user_with_roles('chatwoot_agent'), AutomationRule.new, :index?)).to be(false)
    end
  end

  describe 'ReportPolicy and CampaignPolicy' do
    it 'allow managers and deny agents' do
      manager = user_with_roles('chatwoot_manager')
      agent = user_with_roles('chatwoot_agent')
      expect(permits?(ReportPolicy, manager, :report, :view?)).to be(true)
      expect(permits?(ReportPolicy, agent, :report, :view?)).to be(false)
      expect(permits?(CampaignPolicy, manager, Campaign.new, :index?)).to be(true)
      expect(permits?(CampaignPolicy, agent, Campaign.new, :index?)).to be(false)
    end
  end

  describe 'users without a keycloak role' do
    it 'keep the previous behaviour' do
      agent = user_with_roles
      admin = create(:user, account: account, role: :administrator)
      expect(permits?(ConversationPolicy, agent, conversation, :destroy?)).to be(false)
      expect(permits?(ConversationPolicy, admin, conversation, :destroy?)).to be(true)
      expect(agent.account_users.first.has_permission?(:can_view_all_contacts)).to be(true)
    end
  end
end
