class AppointmentPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def update?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def create?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def destroy?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def search?
    true
  end

  def filter?
    true
  end

  def start?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def complete?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def cancel?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def mark_no_show?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end

  def available_types?
    @account_user.administrator? || @account_user.supervisor? || @account_user.agent?
  end
end
