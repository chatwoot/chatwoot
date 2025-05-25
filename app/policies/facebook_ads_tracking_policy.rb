class FacebookAdsTrackingPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || @account_user.agent?
  end

  def show?
    @account_user.administrator? || @account_user.agent?
  end

  def stats?
    @account_user.administrator? || @account_user.agent?
  end

  def export?
    @account_user.administrator?
  end

  def resend_conversion?
    @account_user.administrator?
  end

  def bulk_resend?
    @account_user.administrator?
  end
end
