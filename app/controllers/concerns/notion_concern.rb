module NotionConcern
  extend ActiveSupport::Concern

  def notion_client
    app_id = GlobalConfigService.load('NOTION_CLIENT_ID', nil)
    app_secret = GlobalConfigService.load('NOTION_CLIENT_SECRET', nil)

    ::OAuth2::Client.new(app_id, app_secret, {
                           site: 'https://api.notion.com',
                           authorize_url: 'https://api.notion.com/v1/oauth/authorize',
                           token_url: 'https://api.notion.com/v1/oauth/token',
                           auth_scheme: :basic_auth
                         })
  end

  private

  def scope
    ''
  end
end
