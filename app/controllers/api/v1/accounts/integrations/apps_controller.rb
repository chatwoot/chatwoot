class Api::V1::Accounts::Integrations::AppsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_apps, only: [:index]
  before_action :fetch_app, only: [:show]

  def index; end

  def show; end

  private

  def fetch_apps
    @apps = Integrations::App.all.select(&:active?)
  end

  def fetch_app
    @app = Integrations::App.find(id: params[:id])
  end
end
