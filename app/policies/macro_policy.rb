class MacroPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    return @record.global? if !author? && @account_user.agent?

    true
  end

  def update?
    author? || @account_user.administrator?
  end

  def destroy?
    author? || orphan_record?
  end

  def execute?
    true
  end

  def attach_file?
    true
  end

  private

  def author?
    @record.created_by == @account_user.user
  end

  def orphan_record?
    return @record.created_by.nil? if @account_user.agent? || @account_user.administrator?

    false
  end
end
