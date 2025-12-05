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

    # Feature enabled: agents see only their contacts
    return false if @record.assignee_id.nil? # Unassigned = admin only

    @record.assignee_id == @user.id
  end

  def update?
    # Class-level authorization
    return true unless @record.is_a?(Contact)

    # Instance-level authorization
    return true if @account_user.administrator?
    return true unless feature_enabled?

    return false if @record.assignee_id.nil?

    @record.assignee_id == @user.id
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
    @account_user.administrator?
  end

  private

  def feature_enabled?
    return false unless @record.is_a?(Contact)
    return false unless @record.account

    @record.account.contact_assignment_enabled?
  end
end
