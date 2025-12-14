class Api::V1::Accounts::Notion::AuthorizationsController < Api::V1::Accounts::OauthAuthorizationController
  include NotionConcern

  def create
    redirect_url = notion_client.auth_code.authorize_url(
      {
        redirect_uri: "#{base_url}/notion/callback",
        response_type: 'code',
        owner: 'user',
        state: state,
        client_id: GlobalConfigService.load('NOTION_CLIENT_ID', nil)
      }
    )

    if redirect_url
      render json: { success: true, url: redirect_url }
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end
end
