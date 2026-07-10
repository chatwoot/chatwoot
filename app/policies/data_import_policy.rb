class DataImportPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator? && record.account_id == account.id
  end

  def create?
    @account_user.administrator?
  end

  def validate_source?
    create?
  end

  def start?
    show?
  end

  def abandon?
    show?
  end

  def skip_logs?
    show?
  end

  def error_logs?
    show?
  end

  class Scope < Scope
    def resolve
      return scope.where(account_id: account.id) if account_user.administrator?

      scope.none
    end
  end
end
