class OrderPolicy < ApplicationPolicy
  def create?
    true
  end

  def index?
    true
  end

  def show?
    true
  end

  def search?
    true
  end
end
