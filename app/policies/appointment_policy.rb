class AppointmentPolicy < ApplicationPolicy
  def create?
    true
  end

  def index?
    true
  end

  def show?
    true
  end
end
