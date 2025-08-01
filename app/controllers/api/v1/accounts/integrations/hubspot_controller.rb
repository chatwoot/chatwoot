class Api::V1::Accounts::Integrations::HubspotController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:auth]
  before_action :check_authorization, except: [:auth]

  def auth
    authorize(:hook)
    access_token = params[:access_token]
    return render json: { error: 'Access token is required' }, status: :unprocessable_entity if access_token.blank?

    # Create a new hook for HubSpot integration
    hook = Current.account.hooks.create!(
      app_id: 'hubspot',
      access_token: access_token,
      status: 'enabled',
      settings: {
        access_token: access_token
      }
    )

    render json: { message: 'HubSpot connected successfully' }
  rescue StandardError => e
    Rails.logger.error("HubSpot auth error: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'hubspot')
  end

  def check_authorization
    authorize(:hook)
  end
end 