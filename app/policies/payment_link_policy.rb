class PaymentLinkPolicy < ApplicationPolicy
  def create?
    true
  end

  def index?
    true
  end

  def search?
    true
  end

  def filter?
    true
  end

  def export?
    true
  end

  def show?
    true
  end

  def cancel?
    true
  end
end
