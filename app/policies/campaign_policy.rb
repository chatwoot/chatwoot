class CampaignPolicy < ApplicationPolicy
  def index?
    @account_user.administrator? || has_campaign_permission?
  end

  def update?
    @account_user.administrator? || has_campaign_permission?
  end

  def show?
    @account_user.administrator? || has_campaign_permission?
  end

  def create?
    @account_user.administrator? || has_campaign_permission?
  end

  def destroy?
    @account_user.administrator? || has_campaign_permission?
  end

  private

  # CommMate: Check if user has campaign_manage permission via custom role
  def has_campaign_permission?
    @account_user.custom_role&.permissions&.include?('campaign_manage')
  end
end
