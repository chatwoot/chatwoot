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
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def set_agent_bot?
    @account_user.administrator?
  end

  def avatar?
    @account_user.administrator?
  end

  def whatsapp_qr?
    # Allow access to WhatsApp QR for administrators and agents assigned to the inbox
    return true if @account_user.administrator?

    Current.user.assigned_inboxes.include? record
  end

  def whatsapp_status?
    # Allow access to WhatsApp status for administrators and agents assigned to the inbox
    return true if @account_user.administrator?

    Current.user.assigned_inboxes.include? record
  end

  def whatsapp_restart_session?
    # Allow access to WhatsApp restart session for administrators and agents assigned to the inbox
    return true if @account_user.administrator?

    Current.user.assigned_inboxes.include? record
  end
end
