class Integrations::Linear::HookBuilder
    attr_reader :params
  
    def initialize(params)
      @params = params
    end
  
    def perform
     token = fetch_access_token
  
      hook = account.hooks.new(
        access_token: token,
        status: 'enabled',
        inbox_id: params[:inbox_id],
        app_id: 'linear',
        settings: { api_key: token }
      )
      hook.save!
      hook
    end
  
    private
  
    def account
      params[:account]
    end
  
    def hook_type
      params[:inbox_id] ? 'inbox' : 'account'
    end
  
    def fetch_access_token
      response = RestClient.post('https://api.linear.app/oauth/token',
        {
          code: params[:code],
          client_id: ENV.fetch('LINEAR_CLIENT_ID', 'TEST_CLIENT_ID'),
          client_secret: ENV.fetch('LINEAR_CLIENT_SECRET', 'TEST_CLIENT_SECRET'),
          redirect_uri: linear_redirect_uri,
          grant_type: 'authorization_code'
        },
        { content_type: 'application/x-www-form-urlencoded' }
      )
  
      JSON.parse(response.body)['access_token']
    rescue RestClient::Exception => e
      Rails.logger.error "Linear OAuth Error: #{e.response.body}"
      error_message = begin
        JSON.parse(e.response.body)['error_description'] || 'Failed to authenticate with Linear'
      rescue JSON::ParserError
        'Failed to authenticate with Linear'
      end
      raise StandardError, error_message
    end
  
    def linear_redirect_uri
      "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/integrations/linear"
    end
  end
  