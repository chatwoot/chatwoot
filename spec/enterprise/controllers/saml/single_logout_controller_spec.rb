require 'rails_helper'

RSpec.describe Saml::SingleLogoutController, type: :request do
  let(:account) { create(:account) }
  let(:idp_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:idp_certificate) { build_certificate(idp_key, 'idp.example.com') }
  let(:request_id) { "_#{SecureRandom.uuid}" }
  let(:saml_settings) do
    create(
      :account_saml_settings,
      account: account,
      certificate: idp_certificate.to_pem,
      idp_entity_id: 'https://idp.example.com/saml/metadata',
      sls_url: 'https://idp.example.com/saml/slo'
    )
  end
  let(:saml_user) do
    create(:user, account: account, email: 'agent@example.com', provider: 'saml').tap do |user|
      user.update!(
        tokens: {
          'client-a' => { 'token' => 'token-a', 'expiry' => 1.month.from_now.to_i },
          'client-b' => { 'token' => 'token-b', 'expiry' => 1.month.from_now.to_i }
        }
      )
      user.user_sessions.create!(client_id: 'client-a', last_activity_at: Time.current)
      user.user_sessions.create!(client_id: 'client-b', last_activity_at: Time.current)
    end
  end

  before do
    account.enable_features!('saml')
    saml_user
  end

  after do
    Redis::Alfred.delete(replay_key(saml_settings, request_id)) if saml_settings.persisted?
  end

  describe 'POST /saml/slo/:settings_token' do
    it 'revokes every Chatwoot session' do
      personal_access_token = saml_user.access_token.token
      allow(Rails.logger).to receive(:info)

      post_logout_request

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens).to eq({})
      expect(saml_user.user_sessions).to be_empty
      expect(saml_user.access_token.reload.token).not_to eq(personal_access_token)
      expect(Rails.logger).to have_received(:info).with(
        "[SAML SLO] Revoked sessions saml_settings_id=#{saml_settings.id} user_id=#{saml_user.id}"
      )
    end

    it 'redirects the back-channel client with a signed LogoutResponse for the configured IdP' do
      post_logout_request

      expect(response).to have_http_status(:found)
      expect(response_redirect_params['SigAlg']).to eq(XMLSecurity::Document::RSA_SHA256)
      expect(response_signature_valid?).to be(true)
      expect(response_document.root['InResponseTo']).to eq(request_id)
      expect(response_document.root['Destination']).to eq(saml_settings.sls_url)
      expect(response_document.at_xpath('/samlp:LogoutResponse/saml:Issuer', response_namespaces).text).to eq(saml_settings.sp_entity_id)
      expect(response_status_code).to eq(Saml::SingleLogoutService::STATUS_SUCCESS)
    end

    it 'echoes RelayState inside the signed redirect response' do
      post_logout_request(relay_state: 'authentik-logout-state')

      expect(response_redirect_params['RelayState']).to eq('authentik-logout-state')
      expect(response_signature_valid?).to be(true)
    end

    it 'rejects RelayState longer than the SAML binding limit before revoking sessions' do
      post_logout_request(relay_state: 'a' * 81)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a request without SAMLRequest' do
      post URI.parse(saml_settings.sp_sls_url).path

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects an unsigned LogoutRequest without revoking sessions' do
      post_logout_request(sign: false)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'documents that ruby-saml considers an unsigned POST-binding LogoutRequest valid' do
      unsigned_request = Base64.strict_decode64(build_logout_request(sign: false))
      ruby_saml_settings = Saml::SingleLogoutService.new(
        saml_settings: saml_settings,
        encoded_request: nil
      ).send(:ruby_saml_settings)
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(
        unsigned_request,
        settings: ruby_saml_settings,
        allowed_clock_drift: Saml::LogoutRequestValidator::ALLOWED_CLOCK_DRIFT
      )

      expect(logout_request.is_valid?).to be(true)
    end

    it 'rejects a signed LogoutRequest wrapped inside an unsigned attacker-controlled root' do
      signed_request = decoded_logout_request.sub(/\A<\?xml.*?\?>/m, '')
      wrapped_request = <<~XML
        <samlp:LogoutRequest xmlns:samlp="#{Saml::LogoutRequestValidator::PROTOCOL_NAMESPACE}"
          xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_attacker" Version="2.0"
          IssueInstant="#{Time.current.utc.iso8601}" Destination="#{saml_settings.sp_sls_url}">
          <saml:Issuer>#{saml_settings.idp_entity_id}</saml:Issuer>
          <samlp:Extensions>#{signed_request}</samlp:Extensions>
          <saml:NameID Format="#{Saml::SingleLogoutService::NAME_ID_FORMAT_EMAIL}">victim@example.com</saml:NameID>
        </samlp:LogoutRequest>
      XML

      post_logout_request(encoded_request: Base64.strict_encode64(wrapped_request))

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a root signature whose reference points to a wrapped LogoutRequest' do
      signed_request = decoded_logout_request.sub(/\A<\?xml.*?\?>/m, '')
      signature = signed_request[%r{<ds:Signature\b.*?</ds:Signature>}m]
      unsigned_inner_request = signed_request.sub(signature, '')
      wrapped_request = <<~XML
        <samlp:LogoutRequest xmlns:samlp="#{Saml::LogoutRequestValidator::PROTOCOL_NAMESPACE}"
          xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_attacker" Version="2.0"
          IssueInstant="#{Time.current.utc.iso8601}" Destination="#{saml_settings.sp_sls_url}">
          #{signature}
          <saml:Issuer>#{saml_settings.idp_entity_id}</saml:Issuer>
          <samlp:Extensions>#{unsigned_inner_request}</samlp:Extensions>
          <saml:NameID Format="#{Saml::SingleLogoutService::NAME_ID_FORMAT_EMAIL}">victim@example.com</saml:NameID>
        </samlp:LogoutRequest>
      XML

      post_logout_request(encoded_request: Base64.strict_encode64(wrapped_request))

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects duplicate ID attributes that make the signature reference ambiguous' do
      signed_request = decoded_logout_request.sub(/\A<\?xml.*?\?>/m, '')
      signature = signed_request[%r{<ds:Signature\b.*?</ds:Signature>}m]
      unsigned_inner_request = signed_request.sub(signature, '')
      wrapped_request = <<~XML
        <samlp:LogoutRequest xmlns:samlp="#{Saml::LogoutRequestValidator::PROTOCOL_NAMESPACE}"
          xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{request_id}" Version="2.0"
          IssueInstant="#{Time.current.utc.iso8601}" Destination="#{saml_settings.sp_sls_url}">
          #{signature}
          <saml:Issuer>#{saml_settings.idp_entity_id}</saml:Issuer>
          <samlp:Extensions>#{unsigned_inner_request}</samlp:Extensions>
          <saml:NameID Format="#{Saml::SingleLogoutService::NAME_ID_FORMAT_EMAIL}">victim@example.com</saml:NameID>
        </samlp:LogoutRequest>
      XML

      post_logout_request(encoded_request: Base64.strict_encode64(wrapped_request))

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a second signature smuggled inside LogoutRequest Extensions' do
      signed_request = decoded_logout_request
      signature = signed_request[%r{<ds:Signature\b.*?</ds:Signature>}m]
      request_with_two_signatures = signed_request.sub(
        '</samlp:LogoutRequest>',
        "<samlp:Extensions>#{signature}</samlp:Extensions></samlp:LogoutRequest>"
      )

      post_logout_request(encoded_request: Base64.strict_encode64(request_with_two_signatures))

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a signed LogoutRequest from a different issuer' do
      allow(Rails.logger).to receive(:warn)

      post_logout_request(issuer: 'https://attacker.example.com/saml/metadata')

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("saml_settings_id=#{saml_settings.id} reason=Doesn't match the issuer")
      )
    end

    it 'rejects a signed LogoutRequest with a different Destination' do
      post_logout_request(destination: "#{saml_settings.sp_sls_url}/other")

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects SHA-1 signature and digest algorithms' do
      post_logout_request(signature_method: XMLSecurity::Document::RSA_SHA1, digest_method: XMLSecurity::Document::SHA1)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects an extra XML signature transform' do
      signed_request = decoded_logout_request
      enveloped_transform = signed_request[%r{<ds:Transform Algorithm=.http://www\.w3\.org/2000/09/xmldsig#enveloped-signature.\s*/?>}]
      xpath_transform = <<~XML.squish
        <ds:Transform Algorithm="http://www.w3.org/TR/1999/REC-xpath-19991116">
          <ds:XPath>true()</ds:XPath>
        </ds:Transform>
      XML
      request_with_extra_transform = signed_request.sub(enveloped_transform, "#{enveloped_transform}#{xpath_transform}")

      post_logout_request(encoded_request: Base64.strict_encode64(request_with_extra_transform))

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'accepts RFC 2045 line-wrapped base64' do
      encoded_request = build_logout_request.scan(/.{1,64}/).join("\n")

      post_logout_request(encoded_request: encoded_request)

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens).to eq({})
    end

    it 'rejects XML with a document type before parsing it with REXML' do
      encoded_request = Base64.strict_encode64('<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><foo>&xxe;</foo>')

      post_logout_request(encoded_request: encoded_request)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a compressed Redirect-binding payload on the POST endpoint' do
      xml = Base64.strict_decode64(build_logout_request)
      encoded_request = Base64.strict_encode64(deflate_request(xml))

      post_logout_request(encoded_request: encoded_request)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects an oversized SAMLRequest before decoding it' do
      encoded_request = 'A' * (Saml::LogoutRequestValidator::MAX_ENCODED_REQUEST_SIZE + 1)

      post_logout_request(encoded_request: encoded_request)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a LogoutRequest signed by a different key' do
      attacker_key = OpenSSL::PKey::RSA.new(2048)
      attacker_certificate = build_certificate(attacker_key, 'attacker.example.com')
      allow(Rails.logger).to receive(:warn)

      post_logout_request(signing_key: attacker_key, signing_certificate: attacker_certificate)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("saml_settings_id=#{saml_settings.id} reason=Certificate of the Signature element does not match")
      )
    end

    it 'verifies the IdP signature before loading the SP private key' do
      attacker_key = OpenSSL::PKey::RSA.new(2048)
      attacker_certificate = build_certificate(attacker_key, 'attacker.example.com')
      saml_settings.update_column(:sp_private_key, 'not-a-private-key') # rubocop:disable Rails/SkipsModelValidations

      post_logout_request(signing_key: attacker_key, signing_certificate: attacker_certificate)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'returns a signed failure for an unknown NameID without revoking another user' do
      post_logout_request(name_id: 'unknown@example.com')

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(response_status_code).to eq(Saml::SingleLogoutService::STATUS_REQUESTER)
      expect(response_signature_valid?).to be(true)
    end

    it 'rejects a signed request sent to the wrong tenant endpoint' do
      other_account = create(:account)
      other_account.enable_features!('saml')
      other_settings = create(
        :account_saml_settings,
        account: other_account,
        certificate: idp_certificate.to_pem,
        idp_entity_id: saml_settings.idp_entity_id,
        sls_url: saml_settings.sls_url
      )
      other_user = create(:user, account: other_account, email: 'other@example.com', provider: 'saml')
      other_user.update!(tokens: { 'other-client' => { 'token' => 'other-token', 'expiry' => 1.month.from_now.to_i } })
      encoded_request = build_logout_request(destination: saml_settings.sp_sls_url)

      post URI.parse(other_settings.sp_sls_url).path, params: { SAMLRequest: encoded_request }

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(other_user.reload.tokens.keys).to contain_exactly('other-client')
    ensure
      Redis::Alfred.delete(replay_key(other_settings, request_id)) if other_settings&.persisted?
    end

    it 'rejects a replay without revoking a session created after the first request' do
      encoded_request = build_logout_request
      post_logout_request(encoded_request: encoded_request)
      expect(response).to have_http_status(:found)

      saml_user.update!(tokens: { 'new-client' => { 'token' => 'new-token', 'expiry' => 1.month.from_now.to_i } })
      allow(Rails.logger).to receive(:warn)
      post_logout_request(encoded_request: encoded_request)

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('new-client')
      expect(response_status_code).to eq(Saml::SingleLogoutService::STATUS_REQUESTER)
      expect(response_signature_valid?).to be(true)
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("saml_settings_id=#{saml_settings.id} reason=LogoutRequest has already been processed")
      )
    end

    it 'fails closed when the replay store is unavailable' do
      allow(Redis::Alfred).to receive(:set).and_raise(Redis::BaseError, 'Redis unavailable')

      post_logout_request

      expect(response).to have_http_status(:service_unavailable)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'fails closed when the IdP SLS URL is not configured' do
      saml_settings.update_columns(sls_url: nil, sp_certificate: nil, sp_private_key: nil) # rubocop:disable Rails/SkipsModelValidations

      post_logout_request

      expect(response).to have_http_status(:unprocessable_entity)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'rejects a stale LogoutRequest' do
      allow(Rails.logger).to receive(:warn)

      post_logout_request(issue_instant: 6.minutes.ago)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("saml_settings_id=#{saml_settings.id} reason=LogoutRequest IssueInstant is outside the accepted time window")
      )
    end

    it 'rejects a LogoutRequest with an IssueInstant too far in the future' do
      post_logout_request(issue_instant: 2.minutes.from_now)

      expect(response).to have_http_status(:bad_request)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'returns a signed failure when NameID is not an email identifier' do
      post_logout_request(name_id_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent')

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(response_signature_valid?).to be(true)
    end

    it 'does not revoke a non-SAML user with the same email address' do
      saml_user.update!(provider: 'email')

      post_logout_request

      expect(response).to have_http_status(:found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
      expect(response_status_code).to eq(Saml::SingleLogoutService::STATUS_REQUESTER)
    end

    it 'rejects a tampered settings token before processing the request' do
      encoded_request = build_logout_request
      path = URI.parse(saml_settings.sp_sls_url).path

      post "#{path}tampered", params: { SAMLRequest: encoded_request }

      expect(response).to have_http_status(:not_found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'does not process logout when the account SAML feature is disabled' do
      account.disable_features!('saml')

      post_logout_request

      expect(response).to have_http_status(:not_found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'does not process logout when SAML is globally disabled' do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('ENABLE_SAML_SSO_LOGIN', 'true').and_return('false')

      post_logout_request

      expect(response).to have_http_status(:not_found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end

    it 'does not expose the endpoint through GET binding' do
      get URI.parse(saml_settings.sp_sls_url).path, params: { SAMLRequest: build_logout_request }

      expect(response).to have_http_status(:not_found)
      expect(saml_user.reload.tokens.keys).to contain_exactly('client-a', 'client-b')
    end
  end

  def post_logout_request(encoded_request: nil, **request_options)
    @response_document = nil
    @response_redirect_params = nil
    @response_raw_redirect_params = nil
    relay_state = request_options.delete(:relay_state)
    encoded_request ||= build_logout_request(**request_options)
    post URI.parse(saml_settings.sp_sls_url).path, params: { SAMLRequest: encoded_request, RelayState: relay_state }.compact
  end

  def build_logout_request(options = {})
    options.reverse_merge!(
      name_id: saml_user.email,
      name_id_format: Saml::SingleLogoutService::NAME_ID_FORMAT_EMAIL,
      destination: saml_settings.sp_sls_url,
      issue_instant: Time.current,
      sign: true,
      signing_key: idp_key,
      signing_certificate: idp_certificate
    )
    document = build_logout_request_document(options)
    sign_logout_request(document, options) if options[:sign]

    Base64.strict_encode64(document.to_s)
  end

  def decoded_logout_request
    Base64.strict_decode64(build_logout_request)
  end

  def build_logout_request_document(options)
    document = XMLSecurity::Document.new
    document.uuid = request_id
    root = add_logout_request_root(document, options)
    add_logout_request_subject(root, options)
    document
  end

  def add_logout_request_root(document, options)
    root = document.add_element('samlp:LogoutRequest', logout_request_namespaces)
    root.add_attributes(
      'ID' => request_id,
      'Version' => '2.0',
      'IssueInstant' => options[:issue_instant].utc.iso8601,
      'Destination' => options[:destination]
    )
    root.add_element('saml:Issuer').text = options.fetch(:issuer, saml_settings.idp_entity_id)
    root
  end

  def add_logout_request_subject(root, options)
    root.add_element('saml:NameID', 'Format' => options[:name_id_format]).text = options[:name_id]
    root.add_element('samlp:SessionIndex').text = 'authentik-session-index'
  end

  def logout_request_namespaces
    {
      'xmlns:samlp' => Saml::LogoutRequestValidator::PROTOCOL_NAMESPACE,
      'xmlns:saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'
    }
  end

  def sign_logout_request(document, options)
    document.sign_document(
      options[:signing_key],
      options[:signing_certificate],
      options.fetch(:signature_method, XMLSecurity::Document::RSA_SHA256),
      options.fetch(:digest_method, XMLSecurity::Document::SHA256)
    )
  end

  def build_certificate(key, common_name)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = SecureRandom.random_number(2**159)
    certificate.subject = OpenSSL::X509::Name.parse("/CN=#{common_name}")
    certificate.issuer = certificate.subject
    certificate.public_key = key.public_key
    certificate.not_before = 1.minute.ago
    certificate.not_after = 1.year.from_now
    certificate.sign(key, OpenSSL::Digest.new('SHA256'))
    certificate
  end

  def response_status_code
    response_document.at_xpath(
      '/samlp:LogoutResponse/samlp:Status/samlp:StatusCode',
      response_namespaces
    )['Value']
  end

  def response_namespaces
    {
      'samlp' => Saml::LogoutRequestValidator::PROTOCOL_NAMESPACE,
      'saml' => 'urn:oasis:names:tc:SAML:2.0:assertion'
    }
  end

  def response_signature_valid?
    parameters = response_redirect_params
    raw_parameters = response_raw_redirect_params
    query = OneLogin::RubySaml::Utils.build_query_from_raw_parts(
      type: 'SAMLResponse',
      raw_data: raw_parameters['SAMLResponse'],
      raw_relay_state: raw_parameters['RelayState'],
      raw_sig_alg: raw_parameters['SigAlg']
    )
    OneLogin::RubySaml::Utils.verify_signature(
      cert: OpenSSL::X509::Certificate.new(saml_settings.sp_certificate),
      sig_alg: parameters['SigAlg'],
      signature: parameters['Signature'],
      query_string: query
    )
  end

  def response_document
    @response_document ||= Nokogiri::XML(inflate_response(response_redirect_params['SAMLResponse']))
  end

  def response_redirect_params
    @response_redirect_params ||= URI.decode_www_form(URI.parse(response.location).query).to_h
  end

  def response_raw_redirect_params
    @response_raw_redirect_params ||= URI.parse(response.location).query.split('&').to_h do |parameter|
      parameter.split('=', 2)
    end
  end

  def inflate_response(encoded_response)
    inflater = Zlib::Inflate.new(-Zlib::MAX_WBITS)
    inflater.inflate(Base64.strict_decode64(encoded_response))
  ensure
    inflater&.close
  end

  def deflate_request(xml)
    deflater = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
    deflater.deflate(xml, Zlib::FINISH)
  ensure
    deflater&.close
  end

  def replay_key(settings, id)
    "saml:single_logout:#{settings.id}:#{Digest::SHA256.hexdigest(id)}"
  end
end
