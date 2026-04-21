class Api::V1::Accounts::Synapseos::DashboardController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def summary
    @summary = ::Synapseos::DashboardSummaryService.new(Current.account, period_days: period_days).call
  end

  private

  def period_days
    days = params[:days].to_i
    days.positive? ? days : 30
  end

  def check_authorization
    authorize(User, :index?)
  end
end
