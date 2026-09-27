class Api::V1::Accounts::Integrations::GiphyController < Api::V1::Accounts::BaseController
  before_action :ensure_giphy_enabled!

  def search
    render json: Integrations::Giphy::SearchService.new(query: params[:q], offset: params[:offset]).perform
  rescue CustomExceptions::GiphyRequestFailed => e
    render json: { error: e.message }, status: e.http_status
  end

  private

  def ensure_giphy_enabled!
    return if Integrations::Giphy::SearchService.enabled?

    render json: { error: I18n.t('errors.giphy.not_configured') }, status: :unprocessable_entity
  end
end
