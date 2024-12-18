class Onehash::Cal::InternalController < Api::V1::Accounts::BaseController
  include RequestExceptionHandler

  def destroy
    account_user = Current.account_user

    Integrations::Hook.where(account_user_id: account_user.id, app_id: 'onehash_cal').destroy_all

    render json: { message: 'Account User hooks deleted successfully' }, status: :ok
  end

  def notify
    account_user = Current.account_user
    render json: { message: 'Account user not found' } unless account_user
    cal_user_slug = params[:cal_user_slug]
    render json: { message: 'Please provide Cal ID slug' } unless cal_user_slug

    url = "#{ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL', nil)}/api/integrations/oh/chat"
    auth_token = ENV.fetch('ONEHASH_API_KEY', nil)

    if auth_token.blank?
      render json: { error: 'OneHash Internal Auth token is not set' }, status: :unauthorized
      return
    end

    begin
      # Prepare the payload for the POST request
      payload = {
        account_user_email: account_user.user.email,
        account_user_id: account_user.id,
        account_name: account_user.account.name,
        cal_user_slug: cal_user_slug
      }

      # Make the POST request using RestClient
      response = RestClient.post(url, payload.to_json, {
                                   content_type: :json,
                                   accept: :json,
                                   Authorization: "Bearer #{auth_token}"
                                 })

      parsed_response = JSON.parse(response.body)
      message = parsed_response['message']
      Rails.logger.info "Message: #{message}"
      render json: { message: message }
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error "HTTP request failed with response: #{e.response}"
      render json: { error: "Failed to notify OneHash: #{e.response}" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error "An error occurred: #{e.message}"
      render json: { error: 'An error occurred while notifying OneHash' }, status: :internal_server_error
    end
  end
end
