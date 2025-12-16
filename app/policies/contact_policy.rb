class ContactPolicy < ApplicationPolicy
  def index?
    true
  end

  def active?
    true
  end

  def import?
    @account_user.administrator?
  end

  def export?
    @account_user.administrator?
  end

  def specific_search?
    true
  end

  def search?
    true
  end

  def filter?
    true
  end

  def show?
    # Class-level authorization (called by before_action :check_authorization)
    return true unless @record.is_a?(Contact)

    # Instance-level authorization (for specific contacts)
    return true if @account_user.administrator?
    return true unless feature_enabled? # Feature disabled = no restrictions

    # Feature enabled: agents can see their contacts OR unassigned contacts
    @record.assignee_id.nil? || @record.assignee_id == @user.id
  end

  def update?
    # Class-level authorization
    return true unless @record.is_a?(Contact)

    # Instance-level authorization
    return true if @account_user.administrator?
    return true unless feature_enabled?

    # Feature enabled: agents can edit their contacts OR unassigned contacts
    @record.assignee_id.nil? || @record.assignee_id == @user.id
  end

  def contactable_inboxes?
    update?
  end

  def destroy_custom_attributes?
    update?
  end

  def create?
    true
  end

  def avatar?
    update?
  end

  def destroy?
    @account_user.administrator?
  end

  def reassign?
    # Class-level authorization (called by before_action :check_authorization)
    return true unless @record.is_a?(Contact)

    # Instance-level authorization
    # Admins can reassign any contact
    return true if @account_user.administrator?

    # Feature disabled: no reassignment for agents
    return false unless feature_enabled?

    # Feature enabled: agents can only claim unassigned contacts (assign to themselves)
    @record.assignee_id.nil?
  end

  private

  def feature_enabled?
    return false unless @record.is_a?(Contact)
    return false unless @record.account

    @record.account.contact_assignment_enabled?
  end
end
