class ConversationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true if @account_user.administrator?
    return true unless feature_enabled?  # Feature disabled = no restrictions

    # Feature enabled: agent can see if they own the contact OR are conversation assignee
    @record.assignee_id == @user.id || @record.contact.assignee_id == @user.id
  end

  def update?
    show?
  end

  def create?
    true
  end

  def toggle_status?
    show?
  end

  def update_last_seen?
    show?
  end

  def unread_count?
    true
  end

  def assign_agent?
    @account_user.administrator?
  end

  private

  def feature_enabled?
    @record.account.contact_assignment_enabled?
  end
end
