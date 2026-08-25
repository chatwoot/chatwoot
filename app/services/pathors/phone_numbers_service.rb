# Reads and mutates the phone-number registry the Pathors platform keeps for the
# organization this account was bound to at consent time.
#
# Binding is what makes a voice inbox real: until Pathors records the number as
# belonging to this account and inbox, an incoming call has nowhere to land. The
# registry is therefore the source of truth for which numbers exist and which
# are still free — this fork never invents a number.
class Pathors::PhoneNumbersService
  REQUEST_TIMEOUT = 10
  NETWORK_ERRORS = [
    HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
    SocketError, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, EOFError
  ].freeze

  pattr_initialize [:account!]

  def list
    response = request(:get, 'phone_numbers')
    # A 401 means the stored token died ahead of its recorded expiry; one forced
    # refresh is the only retry worth making.
    response = request(:get, 'phone_numbers', token: refreshed_access_token) if response.code.to_i == 401
    raise request_failed(response) unless response.code.to_i == 200

    Array(parsed(response)['payload'])
  end

  # `project_id` is the project of the agent bot that answers this inbox: the
  # organization owns the number, a project answers on it. Re-binding the same
  # account and inbox with a different project is how a bot swap re-routes the
  # number, so this is not a create-once call.
  def bind(phone_number_id:, inbox:, project_id:)
    response = request(
      :put,
      "phone_numbers/#{phone_number_id}/binding",
      body: { account_id: account.id, inbox_id: inbox.id, phone_number: inbox.channel.phone_number, project_id: project_id }.to_json
    )
    raise CustomExceptions::Pathors::PhoneNumberAlreadyBound.new({}) if response.code.to_i == 409
    # 422 is Pathors telling us the number or the project we sent no longer
    # matches what it holds — stale wizard data, not an outage.
    raise CustomExceptions::Pathors::BindingRejected.new({}) if response.code.to_i == 422
    raise request_failed(response) unless response.code.to_i == 200

    parsed(response)['binding']
  end

  # Best effort by design: Pathors also releases every binding it holds for an
  # account when it receives the `integration.disconnected` webhook, so a failure
  # here costs cleanup latency, not correctness.
  def unbind(phone_number_id:)
    response = request(:delete, "phone_numbers/#{phone_number_id}/binding")
    return true if response.code.to_i == 200

    Rails.logger.warn("[Pathors] unbinding #{phone_number_id} failed with status #{response.code}")
    false
  rescue StandardError => e
    Rails.logger.warn("[Pathors] unbinding #{phone_number_id} failed: #{e.class} #{e.message}")
    false
  end

  private

  # The URL is built first on purpose: a missing organization id means the
  # integration is not connected, and that must surface before we go looking for
  # a token.
  def request(method, path, body: nil, token: nil)
    url = "#{base_url}/#{path}"
    HTTParty.public_send(
      method,
      url,
      headers: { 'Authorization' => "Bearer #{token || access_token}", 'Content-Type' => 'application/json', 'Accept' => 'application/json' },
      body: body,
      timeout: REQUEST_TIMEOUT
    )
  rescue *NETWORK_ERRORS => e
    Rails.logger.warn("[Pathors] #{method.to_s.upcase} #{path} failed: #{e.class} #{e.message}")
    raise CustomExceptions::Pathors::RequestFailed.new({})
  end

  def request_failed(response)
    Rails.logger.warn("[Pathors] phone number registry responded with #{response.code} for account #{account.id}")
    CustomExceptions::Pathors::RequestFailed.new({})
  end

  def base_url
    "#{GlobalConfigService.load('PATHORS_API_URL', 'https://api.pathors.com')}/org/#{organization_id}/integration/chatwoot"
  end

  def access_token
    @access_token ||= token_service.access_token
  end

  def refreshed_access_token
    token_service.refresh!
  end

  def token_service
    @token_service ||= Integrations::Pathors::AccessTokenService.new(hook: hook)
  end

  # Consent binds a whole Pathors organization, and the registry lives there. A
  # hook carrying only the older `project_id` was granted before organizations
  # existed — which is also before voice binding existed — so reconnecting the
  # integration is the fix, not a second URL shape kept alive here.
  def organization_id
    @organization_id ||= hook.settings.to_h['organization_id'].presence ||
                         raise(CustomExceptions::Pathors::IntegrationNotConnected.new({}))
  end

  def hook
    @hook ||= account.hooks.find_by(app_id: 'pathors', status: :enabled) ||
              raise(CustomExceptions::Pathors::IntegrationNotConnected.new({}))
  end

  def parsed(response)
    body = response.parsed_response
    body.is_a?(Hash) ? body : {}
  rescue StandardError
    {}
  end
end
