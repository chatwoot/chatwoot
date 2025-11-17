class PaymentLinkPolicy < ApplicationPolicy
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
end
