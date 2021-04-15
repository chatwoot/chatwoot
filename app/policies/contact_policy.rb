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

  def search?
    true
  end

  def update?
    true
  end

  def contactable_inboxes?
    true
  end

  def show?
    true
  end

  def create?
    true
  end
end
