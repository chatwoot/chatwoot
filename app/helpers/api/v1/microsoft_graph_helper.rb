require 'httparty'

# This will roll out smtp mail sender in the future
# No use as of now
module Api::V1::MicrosoftGraphHelper
  GRAPH_HOST = 'https://graph.microsoft.com'.freeze

  def make_api_call(method, endpoint, token, payload = nil)
    headervals ||= {}
    headervals[:Authorization] = "Bearer #{token}"
    headervals[:Accept] = 'application/json'

    params ||= {}

    case method.upcase
    when 'GET'
      HTTParty.get "#{GRAPH_HOST}#{endpoint}",
                   headers: headervals,
                   query: params
    when 'POST'
      headervals['Content-Type'] = 'application/json'
      HTTParty.post "#{GRAPH_HOST}#{endpoint}",
                    headers: headervals,
                    query: params,
                    body: payload&.to_json
    else
      raise "HTTP method #{method.upcase} not implemented"
    end
  end

  def send_reply_to_mail(token, _timezone, _subject, body)
    create_message_reply_url = '/v1.0/me/sendMail'

    mail_body = body

    make_api_call 'POST', create_message_reply_url, token, mail_body
  end

  def user_info(access_token)
    make_api_call 'GET', '/v1.0/me/', access_token
  end
end
