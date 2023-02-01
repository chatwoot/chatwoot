# this module has all the methods that are used in the views and controllers
# to get the current account user information
module AccountUserMethods
  extend ActiveSupport::Concern

  def current_account_user
    # We want to avoid subsequent queries in case where the association is preloaded.
    # using where here will trigger n+1 queries.
    account_users.find { |ac_usr| ac_usr.account_id == Current.account.id } if Current.account
  end

  def account
    current_account_user&.account
  end

  def administrator?
    current_account_user&.administrator?
  end

  def agent?
    current_account_user&.agent?
  end

  def role
    current_account_user&.role
  end

  def availability_status
    current_account_user&.availability_status
  end

  def auto_offline
    current_account_user&.auto_offline
  end

  def inviter
    current_account_user&.inviter
  end
end
