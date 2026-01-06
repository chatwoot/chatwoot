class CartPolicy < ApplicationPolicy
  def index?
    true
  end

  def search?
    true
  end
end
