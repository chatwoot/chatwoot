require 'rest-client'
require 'json'

class Api::V1::Accounts::Integrations::OnehashCalController < Api::V1::Accounts::BaseController
  before_action :set_user

  def create
    url = "#{ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL', nil)}/api/integrations/oh/chat"
    auth_token = ENV.fetch('ONEHASH_API_KEY', nil)
    if auth_token.blank?
      render json: { error: 'OneHash Internal Auth token is not set' }, status: :unauthorized
      return
    end
    begin
      response = RestClient.post(url, { email: @user.email }.to_json, {
                                   content_type: :json,
                                   accept: :json,
                                   Authorization: "Bearer #{auth_token}"
                                 })

      data = JSON.parse(response.body)
      @user.custom_attributes['cal_events'] = data['cal_events']

      if @user.save
        render json: { message: 'cal_events successfully updated', cal_events: @user.custom_attributes['cal_events'] }, status: :ok
      else
        render json: { error: 'Failed to update user' }, status: :unprocessable_entity
      end
    rescue RestClient::ExceptionWithResponse => e
      render json: { error: 'Failed to fetch cal_events from external API', details: e.response }, status: :bad_gateway
    end
  end

  def destroy
    if @user.custom_attributes.key?('cal_events')
      @user.custom_attributes.delete('cal_events')

      if @user.save
        render json: { message: 'cal_events successfully deleted' }, status: :ok
      else
        render json: { error: 'Failed to update user' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'cal_events not found' }, status: :not_found
    end
  end

  private

  def set_user
    @user = Current.user
    render json: { error: 'User not found' }, status: :not_found unless @user
  end
end
