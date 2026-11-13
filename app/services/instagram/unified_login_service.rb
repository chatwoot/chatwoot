class Instagram::UnifiedLoginService
  class Error < StandardError
    attr_reader :http_status

    def initialize(message, http_status = nil)
      @http_status = http_status
      super(message)
    end
  end

  def self.credentials
    raise Error, I18n.t('instagram.encryption_required') unless Chatwoot.encryption_configured?

    credentials = {
      client_id: GlobalConfigService.load('INSTAGRAM_UNIFIED_APP_ID', nil),
      client_secret: GlobalConfigService.load('INSTAGRAM_UNIFIED_APP_SECRET', nil)
    }
    raise Error, I18n.t('instagram.missing_credentials') if credentials.values.any?(&:blank?)

    credentials
  end

  def initialize(access_token: nil)
    @access_token = access_token
  end

  def exchange_code(code, redirect_uri)
    request(:get, 'oauth/access_token', self.class.credentials.merge(code: code, redirect_uri: redirect_uri))
  end

  def accounts
    accounts = []
    after = nil
    loop do
      response = request(:get, 'me/assigned_instagram_accounts', { fields: 'id,username', limit: 100, after: after }.compact)
      accounts.concat(response.fetch('data'))
      break unless response.dig('paging', 'next')

      after = response.fetch('paging').fetch('cursors').fetch('after')
    end
    accounts
  end

  def account_details(instagram_id)
    request(:get, instagram_id, { fields: 'id,username' })
  end

  def subscribe(instagram_id)
    response = request(:post, "#{instagram_id}/subscribed_apps", { subscribed_fields: 'messages,message_reactions,messaging_seen' })
    raise Error, I18n.t('instagram.subscription_failed') unless response['success'] == true

    response
  end

  private

  def request(method, path, query)
    version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')
    response = HTTParty.public_send(method, "https://graph.facebook.com/#{version}/#{path}",
                                    query: query, headers: headers, timeout: 30)
    data = JSON.parse(response.body)
    unless response.success? && data['error'].blank?
      raise Error.new(data.dig('error', 'message') || I18n.t('instagram.request_failed'), response.code)
    end

    data
  end

  def headers
    headers = { 'Accept' => 'application/json' }
    headers['Authorization'] = "Bearer #{@access_token}" if @access_token.present?
    headers
  end
end
