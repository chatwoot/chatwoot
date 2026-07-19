class CampaignPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def update?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def create?
    @account_user.administrator?
  end

  def destroy?
    @account_user.administrator?
  end

  def recipients?
    show?
  end

  def stats?
    show?
  end

  def export_recipients?
    show?
  end

  def preview_audience?
    create?
  end
end
