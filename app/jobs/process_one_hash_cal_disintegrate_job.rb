class ProcessOneHashCalDisintegrateJob < ApplicationJob
  queue_as :default

  def perform(id, account_user_id, cal_user_id, account_id)
    # Ensure all necessary parameters are present
    return unless id && account_user_id && cal_user_id && account_id

    Rails.logger.info "Processing disintegration for hook with ID: #{id}"
    user_id = AccountUser.find(account_user_id).user_id

    return unless user_id

    remove_cal_event_from_user(user_id, account_id)
    remove_user_contact_booking(user_id, account_id)
    # return unless from_oauth_controller

    remove_integration_from_cal(account_user_id, cal_user_id)
  end

  private

  def remove_integration_from_cal(account_user_id, cal_user_id)
    # TODO: CAL
    url = "#{ENV.fetch('ONEHASH_CAL_APP_ORIGIN_URL')}/api/integrations/oh/chat"
    # url = 'http://localhost:3001/api/integrations/oh/chat'

    auth_token = ENV.fetch('ONEHASH_API_KEY', nil)
    if auth_token.blank?
      render json: { error: 'OneHash Internal Auth token is not set' }, status: :unauthorized
      return
    end
    url_with_params = "#{url}?account_user_id=#{account_user_id}&cal_user_id=#{cal_user_id}"

    begin
      response = RestClient.delete(url_with_params, {
                                     content_type: :json,
                                     accept: :json,
                                     Authorization: "Bearer #{auth_token}"

                                   })
      parsed_response = JSON.parse(response.body)

      message = parsed_response['message']
      Rails.logger.info "message:#{message}"
    rescue RestClient::ExceptionWithResponse => e
      Rails.logger.error("Failed to trigger disintegrate from Cal (status: #{e.http_code}): #{e.response}")
      nil
    rescue StandardError => e
      Rails.logger.error("Unexpected error while fetching data: #{e.message}")
      nil
    end
  end

  def remove_cal_event_from_user(user_id, account_id)
    # Fetch the user by user_id
    user = User.find(user_id)
    if user
      # Ensure custom_attributes['cal_events'] exists
      user.custom_attributes ||= {}

      account_id_str = account_id.to_s

      # Remove the account_id key from the custom_attributes['cal_events'] hash
      if user.custom_attributes['cal_events'] && user.custom_attributes['cal_events'][account_id_str]
        user.custom_attributes['cal_events'].delete(account_id_str)

        # Save the user object
        if user.save
          Rails.logger.info "User #{user.id}'s calendar event for account_id #{account_id} removed successfully."
        else
          Rails.logger.error "Failed to save user #{user.id} after removing calendar event for account_id #{account_id}."
        end
      end
    else
      Rails.logger.error "User with id #{user_id} not found."
    end
  end

  def remove_user_contact_booking(user_id, account_id)
    ContactBooking.where(user_id: user_id, account_id: account_id).delete_all
  end
end
