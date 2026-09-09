class ContactPolicy < ApplicationPolicy
  def index?
    contact_list_access?
  end

  def active?
    contact_list_access?
  end

  def import?
    @account_user.administrator?
  end

  def export?
    @account_user.administrator?
  end

  def search?
    contact_list_access?
  end

  def filter?
    contact_list_access?
  end

  def update?
    true
  end

  def contactable_inboxes?
    contact_list_access?
  end

  def destroy_custom_attributes?
    true
  end

  def show?
    contact_list_access?
  end

  def create?
    true
  end

  def avatar?
    contact_list_access?
  end

  def destroy?
    @account_user.administrator?
  end

  private

  def contact_list_access?
    @account_user.administrator?
  end
end

ContactPolicy.prepend_mod_with('ContactPolicy')
