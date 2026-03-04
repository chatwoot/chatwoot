class Api::V1::Accounts::Integrations::AppsController < Api::V1::Accounts::BaseController
  HIDDEN_APP_IDS = %w[dialogflow dyte leadsquared].freeze

  before_action :check_admin_authorization?, except: [:index, :show]
  before_action :fetch_apps, only: [:index]
  before_action :fetch_app, only: [:show]

  def index; end

  def show; end

  private

  def fetch_apps
    @apps = Integrations::App.all.select do |app|
      app.active?(Current.account) && !hidden_app?(app.id)
    end
  end

  def fetch_app
    return head :not_found if hidden_app?(params[:id])

    @app = Integrations::App.find(id: params[:id])
    return head :not_found if @app.blank?
  end

  def hidden_app?(app_id)
    HIDDEN_APP_IDS.include?(app_id)
  end
end
