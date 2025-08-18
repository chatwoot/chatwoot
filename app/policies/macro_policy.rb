class MacroPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    @record.global? || author?
  end

  def update?
    author? || (@account_user.administrator? && @record.global?)
  end

  def destroy?
    author? || orphan_record?
  end

  def execute?
    @record.global? || author?
  end

  private

  def author?
    @record.created_by == @account_user.user
  end

  def orphan_record?
    return @account_user.administrator? if @record.created_by.nil? && @record.global?

    false
  end
end
