class ReusableAttachmentPolicy < ApplicationPolicy
  def update?
    @account_user.administrator? || author?
  end

  def destroy?
    update?
  end

  private

  def author?
    @record.created_by == @account_user.user
  end
end
