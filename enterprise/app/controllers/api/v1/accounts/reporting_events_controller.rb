class Api::V1::Accounts::ReportingEventsController < Api::V1::Accounts::EnterpriseAccountsController
  include DateRangeHelper

  RESULTS_PER_PAGE = 25

  before_action :check_admin_authorization?
  before_action :set_reporting_events, only: [:index]
  before_action :set_current_page, only: [:index]

  def index
    @reporting_events = @reporting_events.page(@current_page).per(RESULTS_PER_PAGE)
    @total_count = @reporting_events.total_count
  end

  private

  def set_reporting_events
    @reporting_events = Current.account.reporting_events
                               .includes(:conversation, :user, :inbox)
                               .filter_by_date_range(range)
                               .filter_by_inbox_id(params[:inbox_id])
                               .filter_by_user_id(params[:user_id])
                               .filter_by_name(params[:name])
                               .order(created_at: :desc)
  end

  def set_current_page
    @current_page = (params[:page] || 1).to_i
  end
end
