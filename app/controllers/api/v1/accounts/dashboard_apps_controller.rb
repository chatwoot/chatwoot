class Api::V1::Accounts::DashboardAppsController < Api::V1::Accounts::BaseController
  before_action :authorize_dashboard_app_mutation!, only: [:create, :update, :destroy]
  before_action :fetch_dashboard_apps, except: [:create]
  before_action :fetch_dashboard_app, only: [:show, :update, :destroy]

  def index; end

  def show; end

  def create
    @dashboard_app = Current.account.dashboard_apps.create!(
      permitted_payload.merge(user_id: Current.user.id)
    )
  end

  def update
    @dashboard_app.update!(permitted_payload)
  end

  def destroy
    @dashboard_app.destroy!
    head :no_content
  end

  private

  def fetch_dashboard_apps
    @dashboard_apps = Current.account.dashboard_apps
  end

  def fetch_dashboard_app
    @dashboard_app = @dashboard_apps.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:dashboard_app).permit(
      :title,
      content: [:url, :type]
    )
  end

  def permitted_params
    params.permit(:id)
  end

  def authorize_dashboard_app_mutation!
    account_user = Current.account_user || Current.account.account_users.find_by(user_id: Current.user&.id)

    raise Pundit::NotAuthorizedError unless account_user&.administrator?
  end
end
