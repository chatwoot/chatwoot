require 'httparty'

class MicrosoftGraph
  MS_BASE_URL = "https://login.microsoftonline.com".freeze
  TOKEN_REQUEST_PATH = "oauth2/v2.0/token".freeze

  def initialize(tenant_id)
    @tenant_id = tenant_id
  end

  # Make a request to the Microsoft Graph API, for instance https://graph.microsoft.com/v1.0/users
  def request(url)
    return false unless (token = bearer_token)

    response = HTTParty.get(
      url,
      headers: {
        Authorization: "Bearer #{token}"
      }
    )

    return false unless response.code == 200

    return JSON.parse(response.body)
  end

  private

  # A post to the Microsoft Graph to get a bearer token for the specified tenant.  In this example
  # our Rails application has already been given permission to request these tokens by the admin of
  # the specified tenant_id.
  #
  # See here for more information https://developer.microsoft.com/en-us/graph/docs/concepts/auth_v2_service
  #
  # This request also makes use of the multipart/form-data post body.
  def bearer_token
    response = HTTParty.post(
      "#{MS_BASE_URL}/#{@tenant_id}/#{TOKEN_REQUEST_PATH}",
      multipart: true,
      body: {
        client_id: Rails.application.credentials[Rails.env.to_sym][:microsoft_client_id],
        client_secret: Rails.application.credentials[Rails.env.to_sym][:microsoft_client_secret],
        scope: 'https://graph.microsoft.com/.default',
        grant_type: 'client_credentials'
      }
    )

    return false unless response.code == 200

    JSON.parse(response.body)['access_token']
  end
end
