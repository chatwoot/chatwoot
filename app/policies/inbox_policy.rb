class InboxPolicy < ApplicationPolicy
  class Scope
    attr_reader :user_context, :user, :scope, :account, :account_user

    def initialize(user_context, scope)
      @user_context = user_context
      @user = user_context[:user]
      @account = user_context[:account]
      @account_user = user_context[:account_user]
      @scope = scope
    end

    def resolve
      user.assigned_inboxes
    end
  end

  def index?
    true
  end

  def show?
    # FIXME: for agent bots, lets bring this validation to policies as well in future
    return true if @user.is_a?(AgentBot)

    Current.user.assigned_inboxes.include? record
  end

  def assignable_agents?
    true
  end

  def agent_bot?
    true
  end

  def campaigns?
    @account_user.administrator? || has_campaign_permission?
  end

  def create?
    # CommMate: Allow administrators or users with settings_inboxes_manage permission
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  def update?
    # CommMate: Allow administrators or users with settings_inboxes_manage permission
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  def destroy?
    # CommMate: Allow administrators or users with settings_inboxes_manage permission
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  def set_agent_bot?
    # CommMate: Allow administrators or users with settings_inboxes_manage permission
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  def avatar?
    # CommMate: Allow administrators or users with settings_inboxes_manage permission
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  def sync_templates?
    # CommMate: Allow administrators or users with templates_manage permission
    @account_user.administrator? || has_templates_permission?
  end

  def health?
    @account_user.administrator? || has_inboxes_manage_permission?
  end

  # CommMate: Allow templates_manage permission for managing WhatsApp templates
  def manage_templates?
    @account_user.administrator? || has_templates_permission?
  end

  private

  # CommMate: Check if user has templates_manage via per-user access_permissions
  def has_templates_permission?
    @account_user.permissions.include?('templates_manage')
  end

  # CommMate: Check if user has settings_inboxes_manage permission
  def has_inboxes_manage_permission?
    @account_user.permissions.include?('settings_inboxes_manage')
  end

  # CommMate: Check if user has campaign_manage permission
  def has_campaign_permission?
    @account_user.permissions.include?('campaign_manage')
  end
end
