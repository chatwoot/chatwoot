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

  # Kiraid: firing a one_off (cold-outreach) campaign immediately is an admin-only
  # action, consistent with create/update. Without this Pundit falls back to the
  # ApplicationPolicy default, which denies every action, so the dashboard "Send"
  # button would 403.
  def trigger?
    @account_user.administrator?
  end
end
