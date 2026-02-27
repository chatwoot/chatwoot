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

  def cancel?
    true
  end

  def destroy?
    true
  end
end
