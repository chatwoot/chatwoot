class WechatKf::ApiClient
  API_BASE = 'https://qyapi.weixin.qq.com/cgi-bin'.freeze

  def initialize(integration)
    @integration = integration
  end

  def sync_messages(open_kfid:, token:, cursor:)
    body = { open_kfid: open_kfid, limit: 1000 }
    body[:token] = token if token.present?
    body[:cursor] = cursor if cursor.present?
    post('/kf/sync_msg', body)
  end

  def send_text(open_kfid:, external_userid:, content:, msgid:)
    post('/kf/send_msg', touser: external_userid, open_kfid: open_kfid, msgid: msgid,
                         msgtype: 'text', text: { content: content })
  end

  private

  def post(path, body)
    response = HTTParty.post(
      "#{API_BASE}#{path}",
      query: { access_token: access_token },
      headers: { 'Content-Type' => 'application/json' },
      body: body.to_json
    )
    check_response(response)
  end

  def access_token
    Rails.cache.fetch("wechat_kf/access_token/#{@integration.id}", expires_in: 90.minutes) do
      response = HTTParty.get("#{API_BASE}/gettoken", query: { corpid: @integration.corp_id, corpsecret: @integration.corp_secret })
      check_response(response).fetch('access_token')
    end
  end

  def check_response(response)
    body = response.parsed_response
    raise CustomExceptions::WechatKfApiError, "WeChat Customer Service HTTP #{response.code}" unless response.success? && body.is_a?(Hash)
    raise CustomExceptions::WechatKfApiError, "WeChat Customer Service #{body['errcode']}: #{body['errmsg']}" unless body['errcode']&.zero?

    body
  end
end
