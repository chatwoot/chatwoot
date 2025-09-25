class AppleMessagesForBusiness::LandingPageController < ApplicationController
  before_action :find_channel

  def show
    return render_error('Missing state parameter') unless params[:state]

    provider = params[:provider] || extract_provider_from_state(params[:state])
    return render_error('Missing provider parameter') unless provider

    auth_service = AppleMessagesForBusiness::AuthenticationService.new(@channel)

    # Generate the OAuth2 URL for the specified provider
    success_url = apple_messages_oauth_callback_url(
      msp_id: @channel.msp_id,
      state: params[:state]
    )

    cancel_url = params[:cancel_url]

    oauth_url = auth_service.generate_landing_page_url(provider, success_url, cancel_url)

    if oauth_url.is_a?(Hash) && oauth_url[:error]
      render_error(oauth_url[:error])
    else
      redirect_to oauth_url, allow_other_host: true
    end
  end

  def create_authentication_request
    return render json: { error: 'Missing provider' } unless params[:provider]

    provider = params[:provider]
    redirect_uri = params[:redirect_uri] || default_redirect_uri
    state = params[:state] || SecureRandom.hex(32)

    auth_service = AppleMessagesForBusiness::AuthenticationService.new(@channel)
    request_data = auth_service.create_authentication_request(provider, redirect_uri, state)

    render json: {
      authentication_request: request_data,
      landing_page_url: apple_messages_landing_page_url(
        msp_id: @channel.msp_id,
        provider: provider,
        state: state
      )
    }
  rescue StandardError => e
    render json: { error: "Failed to create authentication request: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def find_channel
    @channel = Channel::AppleMessagesForBusiness.find_by!(msp_id: params[:msp_id])
  rescue ActiveRecord::RecordNotFound
    render_error('Channel not found')
  end

  def extract_provider_from_state(state)
    auth_sessions = @channel.auth_sessions || {}
    session = auth_sessions[state]

    return nil unless session

    session['provider']
  end

  def default_redirect_uri
    apple_messages_oauth_callback_url(
      msp_id: @channel.msp_id,
      state: params[:state] || SecureRandom.hex(32)
    )
  end

  def render_error(error_message)
    landing_service = AppleMessagesForBusiness::LandingPageService.new(@channel)
    page_data = landing_service.generate_error_page(error_message)

    render html: page_data[:html].html_safe, content_type: page_data[:content_type], status: page_data[:status]
  end

  def apple_messages_oauth_callback_url(msp_id:, state:)
    "#{request.base_url}/apple_messages_for_business/#{msp_id}/oauth/callback?state=#{state}"
  end

  def apple_messages_landing_page_url(msp_id:, provider:, state:)
    "#{request.base_url}/apple_messages_for_business/#{msp_id}/oauth/landing?provider=#{provider}&state=#{state}"
  end
end