class TicketPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def assign?
    true
  end

  def resolve?
    true
  end
end
