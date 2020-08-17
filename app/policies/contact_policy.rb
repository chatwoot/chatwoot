class ContactPolicy < ApplicationPolicy
  def index?
    true
  end

  def search?
    true
  end

  def update?
    true
  end

  def show?
    true
  end

  def create?
    true
  end
end
