class CartPolicy < ApplicationPolicy
  def create?
    true
  end

  def index?
    true
  end

  def search?
    true
  end
end
