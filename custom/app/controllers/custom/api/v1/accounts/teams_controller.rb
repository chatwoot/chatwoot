module Custom::Api::V1::Accounts::TeamsController
  def self.prepended(base)
    base.include Custom::Concerns::QuotaEnforcement
    base.before_action :check_teams_quota, only: [:create]
  end

  private

  def check_teams_quota
    check_quota(:teams)
  end
end
