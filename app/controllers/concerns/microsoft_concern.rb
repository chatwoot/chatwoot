module MicrosoftConcern
  extend ActiveSupport::Concern

  def microsoft_client
    ::OAuth2::Client.new(ENV.fetch('AZURE_APP_ID', nil), ENV.fetch('AZURE_APP_SECRET', nil),
                         {
                           site: 'https://login.microsoftonline.com',
                           authorize_url: "https://login.microsoftonline.com/#{azure_tenant_id}/oauth2/v2.0/authorize",
                           token_url: "https://login.microsoftonline.com/#{azure_tenant_id}/oauth2/v2.0/token"
                         })
  end

  private

  def parsed_body
    @parsed_body ||= Rack::Utils.parse_nested_query(@response.raw_response.body)
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def azure_tenant_id
    MicrosoftGraphAuth.azure_tenant_id
  end
end
