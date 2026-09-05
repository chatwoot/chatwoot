module Enterprise::ContactPolicy
  def index?
    contact_access? || super
  end

  def active?
    contact_access? || super
  end

  def search?
    contact_access? || super
  end

  def filter?
    contact_access? || super
  end

  def show?
    contact_access? || super
  end

  def contactable_inboxes?
    contact_access? || super
  end

  def avatar?
    contact_access? || super
  end

  def update?
    return true if @account_user.custom_role_permission?('contact_manage', 'contact_edit')
    return false if @account_user.custom_role.present?

    super
  end

  def destroy?
    @account_user.custom_role_permission?('contact_delete') || super
  end

  def export?
    @account_user.custom_role_permission?('contact_manage') || super
  end

  def import?
    @account_user.custom_role_permission?('contact_manage') || super
  end

  private

  def contact_access?
    @account_user.custom_role_permission?('contact_manage', 'contact_inbox_manage')
  end
end
