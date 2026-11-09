class Api::V1::Accounts::Integrations::AppsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?, except: [:index, :show]
  before_action :fetch_apps, only: [:index]
  before_action :fetch_app, only: [:show]

  def index; end

  def show; end

  private

  def fetch_apps
    @apps = Integrations::App.all.select do |app|
      app.active?(Current.account) ||
        (app.id == 'stripe' && Current.account_user&.administrator? && Current.account.hooks.exists?(app_id: 'stripe'))
    end
  end

  def fetch_app
    @app = Integrations::App.find(id: params[:id])
    return unless %w[shopify stripe].include?(@app&.id)

    # Keep direct lookups subject to the same availability checks as the integrations list.
    raise ActiveRecord::RecordNotFound unless @app.active?(Current.account)
  end
end
