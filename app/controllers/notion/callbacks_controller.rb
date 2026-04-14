class Notion::CallbacksController < OauthCallbackController
  include NotionConcern

  private

  def provider_name
    'notion'
  end

  def oauth_client
    notion_client
  end

  def handle_response
    hook = account.hooks.new(
      access_token: parsed_body['access_token'],
      status: 'enabled',
      app_id: 'notion',
      settings: {
        token_type: parsed_body['token_type'],
        workspace_name: parsed_body['workspace_name'],
        workspace_id: parsed_body['workspace_id'],
        workspace_icon: parsed_body['workspace_icon'],
        bot_id: parsed_body['bot_id'],
        owner: parsed_body['owner']
      }
    )

    hook.save!
    redirect_to notion_redirect_uri
  end

  def notion_redirect_uri
    "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{account.id}/settings/integrations/notion"
  end
end
