class Api::V1::Accounts::WorkingHoursController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_webhook, only: [:update]

  def update
    @working_hour.update!(working_hour_params)
  end

  private

  def working_hour_params
    params.require(:working_hour).permit(:inbox_id, :open_hour, :open_minutes, :close_hour, :close_minutes, :closed_all_day)
  end

  def fetch_working_hour
    @working_hour = Current.account.working_hours.find(params[:id])
  end
end
