class DataExportPolicy < ApplicationPolicy
  def index?
    ContactPolicy.new(user_context, Contact).export?
  end

  def create?
    index?
  end

  def show?
    index? && record.account_id == account.id
  end

  def download?
    show?
  end

  def rerun?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.where(account_id: account.id) if ContactPolicy.new(user_context, Contact).export?

      scope.none
    end
  end
end
