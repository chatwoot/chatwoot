class ProductMediumPolicy < ApplicationPolicy
  def set_primary?
    @account_user.administrator? || @account_user.agent?
  end
end
