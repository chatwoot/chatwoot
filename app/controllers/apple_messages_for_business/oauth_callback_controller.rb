class AppleMessagesForBusiness::OauthCallbackController < ApplicationController
  before_action :find_channel

  def process_callback
    return render_error('Missing authorization code') unless params[:code]
    return render_error('Missing state parameter') unless params[:state]

    provider = extract_provider_from_state(params[:state])
    return render_error('Invalid provider') unless provider

    auth_service = AppleMessagesForBusiness::AuthenticationService.new(@channel)
    result = auth_service.process_oauth2_callback(params[:code], params[:state], provider)

    if result[:error]
      render_error(result[:error])
    else
      render_success(result, provider)
    end
  end

  def landing_page
    return render_error('Missing state parameter') unless params[:state]

    provider = extract_provider_from_state(params[:state])
    return render_error('Invalid provider') unless provider

    landing_service = AppleMessagesForBusiness::LandingPageService.new(@channel)
    page_data = landing_service.generate_landing_page(params[:state], provider)

    render html: page_data[:html].html_safe, content_type: page_data[:content_type], status: page_data[:status]
  end

  private

  def find_channel
    @channel = Channel::AppleMessagesForBusiness.find_by!(msp_id: params[:msp_id])
  rescue ActiveRecord::RecordNotFound
    render_error('Channel not found')
  end

  def extract_provider_from_state(state)
    # Extract provider from stored auth session
    auth_sessions = @channel.auth_sessions || {}
    session = auth_sessions[state]

    return nil unless session

    session['provider']
  end

  def render_success(result, provider)
    landing_service = AppleMessagesForBusiness::LandingPageService.new(@channel)
    page_data = landing_service.generate_success_page(result[:user], provider)

    # Store the successful authentication for potential message creation
    store_authentication_result(result, provider)

    render html: page_data[:html].html_safe, content_type: page_data[:content_type], status: page_data[:status]
  end

  def render_error(error_message)
    landing_service = AppleMessagesForBusiness::LandingPageService.new(@channel)
    page_data = landing_service.generate_error_page(error_message)

    render html: page_data[:html].html_safe, content_type: page_data[:content_type], status: page_data[:status]
  end

  def store_authentication_result(result, provider)
    # Store the authentication result temporarily for message creation
    auth_key = "apple_auth_result:#{@channel.id}:#{SecureRandom.hex(16)}"

    Redis.current.setex(
      auth_key,
      3600, # 1 hour
      {
        user: result[:user],
        provider: provider,
        authenticated_at: result[:authenticated_at],
        channel_id: @channel.id
      }.to_json
    )

    # Trigger a webhook or notification that authentication is complete
    # This can be used to send the authentication response back to the user
    trigger_authentication_notification(auth_key, result, provider)
  end

  def trigger_authentication_notification(auth_key, result, provider)
    # This could trigger a job to send an Apple Messages response
    # or update the conversation with the authentication result
    AppleMessagesForBusiness::AuthenticationCompleteJob.perform_later(
      channel_id: @channel.id,
      auth_key: auth_key,
      user_data: result[:user],
      provider: provider
    )
  end
end