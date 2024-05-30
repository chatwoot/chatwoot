class OauthCallbackController < ApplicationController
  def show
    @response = oauth_client.auth_code.get_token(
      oauth_code,
      redirect_uri: "#{base_url}/#{provider_name}/callback"
    )

    handle_response
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to '/'
  end

  private

  def oauth_code
    params[:code]
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def parsed_body
    @parsed_body ||= Rack::Utils.parse_nested_query(@response.raw_response.body)
  end

  # These methods should be implemented in the subclasses
  def oauth_client
    raise NotImplementedError
  end

  def provider_name
    raise NotImplementedError
  end

  def handle_response
    raise NotImplementedError
  end
end
