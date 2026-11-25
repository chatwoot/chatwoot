require 'rails_helper'

# A credential check that did not answer is not a verdict. It must not reach the operator as a 500,
# which says the application broke, nor as "Invalid Credentials", which says Meta refused something it
# never got to look at. Every example goes through the real controller and the real provider service,
# with the network arranged at the HTTP layer: a double of the validation or of the provider agrees with
# whatever the code does, and the validation is exactly the boundary under test.
RSpec.describe 'WhatsApp credential check', type: :request do
  let(:account) { create(:account) }
  let(:refusal) { json(401, { error: { message: 'Invalid OAuth access token', code: 190 } }) }
  let(:templates_ok) { json(200, { data: [] }) }
  let(:owned_number) { json(200, { data: [{ id: '123456789' }] }) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:graph) { %r{graph\.facebook\.com/v14\.0/123456789/} }
  let(:secret) { 'EAAsegredo598xyz' }

  let(:cloud_config) { { api_key: secret, phone_number_id: '123456789', business_account_id: '123456789', app_secret: 'meta-app-secret' } }

  def create_inbox(channel)
    post "/api/v1/accounts/#{account.id}/inboxes",
         params: { name: 'WA 598', channel: { type: 'whatsapp', phone_number: '+15550005980', **channel } },
         headers: admin.create_new_auth_token, as: :json
  end

  def create_cloud_inbox = create_inbox(provider: 'whatsapp_cloud', provider_config: cloud_config)

  def message = response.parsed_body['message']
  def rows = Channel::Whatsapp.where(phone_number: '+15550005980').count

  def graph_answers(templates:, phone_numbers: nil)
    stub_request(:get, /#{graph}message_templates/).to_return(**templates)
    stub_request(:get, /#{graph}phone_numbers/).to_return(**phone_numbers) if phone_numbers
  end

  def json(status, body) = { status: status, body: body.to_json, headers: { 'Content-Type' => 'application/json' } }

  # The two sentences are measured in the same run rather than written down here, so that a change to
  # either wording does not turn this suite into a record of the old one. What is asserted is that they
  # are two different sentences, and which one each outcome gets.
  def refusal_sentence
    graph_answers(templates: refusal)
    create_cloud_inbox
    WebMock.reset!
    message
  end

  describe 'creating an inbox' do
    it 'answers 422 with its own sentence when the check does not come back, and writes nothing' do
      stub_request(:get, /#{graph}message_templates/).to_timeout

      create_cloud_inbox

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to eq("Provider config #{I18n.t('errors.inboxes.channel.credential_check_unavailable')}")
      expect(rows).to eq(0)
      expect(Inbox.where(name: 'WA 598')).to be_empty
    end

    it 'keeps a refusal from Meta reading as a refusal, and not as the check being unavailable' do
      graph_answers(templates: refusal)

      create_cloud_inbox

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to eq('Provider config Invalid Credentials')
      expect(rows).to eq(0)
    end

    it 'says two different things for the two outcomes, so neither can quietly stand in for the other' do
      refused = refusal_sentence
      stub_request(:get, /#{graph}message_templates/).to_timeout
      create_cloud_inbox

      expect(message).not_to eq(refused)
      expect(message).not_to include('Invalid Credentials')
    end

    it 'still creates the inbox when the check passes' do
      # A created manual-flow channel sets up its webhooks after commit, against the v22.0 Graph. That
      # is past the validation this file is about, so it is answered here and nowhere else; registered
      # first, so the specific stubs below still win for the calls the check makes.
      stub_request(:any, /graph\.facebook\.com/).to_return(json(200, {}))
      graph_answers(templates: templates_ok, phone_numbers: owned_number)

      create_cloud_inbox

      expect(response).to have_http_status(:ok)
      expect(rows).to eq(1)
    end

    it 'treats silence on the second call of the check as silence too' do
      graph_answers(templates: templates_ok)
      stub_request(:get, /#{graph}phone_numbers/).to_timeout

      create_cloud_inbox

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(rows).to eq(0)
    end

    it 'keeps a phone number that does not belong to the account as a refusal' do
      graph_answers(templates: templates_ok, phone_numbers: json(200, { data: [{ id: 'someone-else' }] }))

      create_cloud_inbox

      expect(message).to eq('Provider config Invalid Credentials')
    end

    # Silence is not only a timeout: nothing listening, a reply that started and stopped, and a name that
    # did not resolve all leave the same thing, which is no answer to classify.
    [Errno::ECONNREFUSED, Net::ReadTimeout, SocketError].each do |failure|
      it "sends #{failure} out through the same door as a timeout" do
        stub_request(:get, /#{graph}message_templates/).to_raise(failure)

        create_cloud_inbox

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
        expect(rows).to eq(0)
      end
    end

    # A 5xx is Meta, or whatever sits in front of it, saying it could not answer right now. It says
    # nothing about the credential, so it must not reach the operator as a refusal.
    {
      '500 in Meta shape' => { status: 500, body: { error: { message: 'An unknown error occurred', code: 1 } }.to_json,
                               headers: { 'Content-Type' => 'application/json' } },
      '502 from a gateway' => { status: 502, body: '<html>502 Bad Gateway</html>', headers: { 'Content-Type' => 'text/html' } },
      '503 with no body' => { status: 503, body: '' }
    }.each do |shape, answer|
      it "does not call a #{shape} a refusal" do
        graph_answers(templates: answer)

        create_cloud_inbox

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message).not_to include('Invalid Credentials')
        expect(rows).to eq(0)
      end
    end

    # A rate limit is a 4xx, and in #632 a 429 was read as a refusal because the question there was
    # whether a registration attempt landed, and a 429 answers that: it did not. The question here is
    # whether the credential is good, and a ceiling on request rate says nothing about that, so the same
    # status code gets the other answer.
    it 'does not call a rate limit a refusal of the credential' do
      graph_answers(templates: json(429, { error: { message: '(#80007) Rate limit hit', code: 80_007 } }))

      create_cloud_inbox

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).not_to include('Invalid Credentials')
    end

    # HTTParty parses by the Content-Type it is given, so an unreadable body is not only bad JSON: a
    # gateway answering XML raises a parser error of another class.
    {
      'JSON' => { body: 'not json at all', headers: { 'Content-Type' => 'application/json' } },
      'XML' => { body: '<data><id>123456789</id', headers: { 'Content-Type' => 'application/xml' } }
    }.each do |format, unreadable|
      it "does not bring the request down when Meta answers 200 with #{format} this side cannot read" do
        graph_answers(templates: templates_ok, phone_numbers: { status: 200, **unreadable })

        create_cloud_inbox

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
        expect(rows).to eq(0)
      end
    end

    # The rescue that turns silence into a sentence must not also swallow a defect of our own. A
    # NoMethodError sold to the operator as an inconclusive check tells them to try again, forever, and
    # hides the one thing somebody has to fix.
    it 'does not sell a defect of our own as an inconclusive check' do
      graph_answers(templates: templates_ok, phone_numbers: owned_number)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_raise(NoMethodError, 'planted 598')

      create_cloud_inbox

      expect(message.to_s).not_to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(message.to_s).not_to include('Invalid Credentials')
      expect(rows).to eq(0)
    end

    it 'never puts the credential in the log, and does log the failure' do
      lines = []
      %i[warn error].each do |level|
        allow(Rails.logger).to(receive(level).and_wrap_original do |original, *args|
          lines << args.first.to_s
          original.call(*args)
        end)
      end
      stub_request(:get, /#{graph}message_templates/).to_timeout

      create_cloud_inbox

      expect(lines.join("\n")).not_to include(secret)
      expect(lines).to include(a_string_matching(/credential check/i))
    end
  end

  describe 'updating an inbox' do
    let!(:channel) do
      create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
    end

    def update_config(config)
      patch "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}",
            params: { channel: { provider_config: config } }, headers: admin.create_new_auth_token, as: :json
    end

    it 'answers 422 on silence and leaves the row that was working exactly as it was' do
      before = channel.reload.provider_config.dup
      stub_request(:get, %r{graph\.facebook\.com/v14\.0/.+/message_templates}).to_timeout

      update_config(channel.provider_config.merge('api_key' => 'rotated-key'))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(channel.reload.provider_config).to eq(before)
    end

    # The embedded-to-manual transfer is the one path where the refusal log parses Meta's body. When that
    # body is unreadable, building the log line raised, and a refusal the app had already recognised came
    # out as a 500. Meta answered 401: the verdict is a refusal, and a log line must not change it.
    {
      'JSON' => { body: 'not json at all', headers: { 'Content-Type' => 'application/json' } },
      'XML' => { body: '<error><message>bad token</message', headers: { 'Content-Type' => 'application/xml' } }
    }.each do |format, unreadable|
      it "keeps a 401 a refusal when its #{format} body cannot be read" do
        # The factory writes `source: 'embedded_signup'` whenever the config does not name a source, so the
        # channel is already on the embedded path and sending the config without it is the transfer.
        expect(channel.reload.provider_config['source']).to eq('embedded_signup')
        stub_request(:get, %r{graph\.facebook\.com/v14\.0/.+/message_templates}).to_return(status: 401, **unreadable)

        update_config(channel.provider_config.except('source').merge('api_key' => 'rotated-key', 'app_secret' => 'manual-app-secret'))

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message).to eq('Provider config Invalid Credentials')
      end
    end

    # Tolerating an unreadable body in that log line must not grow into tolerating a defect of ours there.
    it 'lets a defect of our own in the refusal log escape as itself' do
      stub_request(:get, %r{graph\.facebook\.com/v14\.0/.+/message_templates})
        .to_return(status: 401, body: { error: { message: 'bad token' } }.to_json, headers: { 'Content-Type' => 'application/json' })
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_wrap_original do |original, **kwargs|
        original.call(**kwargs).tap { |provider| allow(provider).to receive(:credential_check_body).and_raise(NoMethodError, 'planted 598') }
      end

      update_config(channel.provider_config.except('source').merge('api_key' => 'rotated-key', 'app_secret' => 'manual-app-secret'))

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include('planted 598')
    end
  end

  describe 'converting a provider' do
    let!(:channel) do
      create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false)
    end

    it 'carries the same sentence and leaves the provider that was working untouched' do
      before_provider = channel.reload.provider
      before_config = channel.provider_config.dup
      teardown = stub_request(:delete, %r{/connections/})
      stub_request(:get, %r{graph\.facebook\.com/v14\.0/waba9/message_templates}).to_timeout

      post "/api/v1/accounts/#{account.id}/inboxes/#{channel.inbox.id}/convert_provider",
           params: { provider: 'whatsapp_cloud', provider_config: { api_key: 'k9', phone_number_id: 'pn9', business_account_id: 'waba9' } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(channel.reload.provider).to eq(before_provider)
      expect(channel.provider_config).to eq(before_config)
      expect(teardown).not_to have_been_requested
    end
  end

  # Embedded signup builds the channel and hands it to `Inbox.create!`. An invalid channel used to fail its
  # autosave quietly, the inbox insert then reached the database with a null channel_id, and what the
  # operator read was the database's sentence. Silence becoming a validation error would have walked
  # straight into that, so the channel is saved on its own first.
  describe 'embedded signup' do
    before do
      allow(Whatsapp::TokenExchangeService).to receive(:new).and_return(instance_double(Whatsapp::TokenExchangeService, perform: secret))
      allow(Whatsapp::PhoneInfoService).to receive(:new).and_return(
        instance_double(Whatsapp::PhoneInfoService,
                        perform: { phone_number: '+15550005980', phone_number_id: '123456789', business_name: 'Acme',
                                   display_phone_number: '15550005980' })
      )
    end

    def authorize
      post "/api/v1/accounts/#{account.id}/whatsapp/authorization",
           params: { code: 'code598', business_id: 'biz598', waba_id: '123456789', phone_number_id: '123456789' },
           headers: admin.create_new_auth_token, as: :json
    end

    it 'answers silence with the validation sentence, not with the database or the raw exception' do
      stub_request(:get, /#{graph}message_templates/).to_timeout

      authorize

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to match(/PG::|null value in column|violates not-null constraint|execution expired/)
      expect(response.body).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(rows).to eq(0)
      expect(Inbox.where(account: account)).to be_empty
    end
  end

  describe 'the other providers that check over the network' do
    it 'sends silence from zapi out through the same door' do
      stub_request(:get, %r{api\.z-api\.io/instances/.+/status}).to_timeout

      create_inbox(provider: 'zapi', provider_config: { instance_id: 'inst598', token: 'tok598segredo', client_token: 'ct' })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
      expect(rows).to eq(0)
    end

    it 'sends silence from baileys out through the same door' do
      stub_request(:get, %r{baileys\.test/status/auth}).to_timeout

      create_inbox(provider: 'baileys', provider_config: { provider_url: 'https://baileys.test', api_key: 'k' })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
    end

    it 'sends silence from 360dialog out through the same door' do
      stub_request(:post, %r{/configs/webhook}).to_timeout

      create_inbox(provider: 'default', provider_config: { api_key: 'k' })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(message).to include(I18n.t('errors.inboxes.channel.credential_check_unavailable'))
    end

    it 'keeps a refusal from zapi a refusal' do
      stub_request(:get, %r{api\.z-api\.io/instances/.+/status}).to_return(json(401, { error: 'bad token' }))

      create_inbox(provider: 'zapi', provider_config: { instance_id: 'inst598', token: 'tok598segredo', client_token: 'ct' })

      expect(message).to eq('Provider config Invalid Credentials')
    end
  end

  # The defect planted on `.new` above sits before the provider runs at all, so it cannot tell a rescue
  # around the HTTP call from one that grew to cover the whole check. These sit where a grown rescue
  # would reach: the code of ours that builds the request, the code between Meta's two calls, and the
  # code that reads an answer that did come back.
  #
  # What is asserted is the defect itself reaching the response. Checking only that neither sentence
  # appears in the body cannot work here: the test environment renders the exception page with the
  # model's source around the failing line, and that source contains the refusal string.
  describe 'a defect of our own inside the check' do
    def plant(service, method_name)
      allow(service).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap { |provider| allow(provider).to receive(method_name).and_raise(NoMethodError, 'planted 598') }
      end
    end

    def expect_the_defect_to_escape
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include('planted 598')
      expect(rows).to eq(0)
    end

    it 'escapes as itself from the code that builds the whatsapp_cloud request' do
      plant(Whatsapp::Providers::WhatsappCloudService, :business_account_path)

      create_cloud_inbox

      expect_the_defect_to_escape
    end

    it 'escapes as itself from between the two whatsapp_cloud calls' do
      graph_answers(templates: templates_ok, phone_numbers: owned_number)
      plant(Whatsapp::Providers::WhatsappCloudService, :phone_number_belongs_to_waba?)

      create_cloud_inbox

      expect_the_defect_to_escape
    end

    # The other expression between the two calls reads the channel, not the provider, so the defect is
    # planted on the channel the provider was built with.
    it 'escapes as itself from the channel read between the two whatsapp_cloud calls' do
      graph_answers(templates: templates_ok, phone_numbers: owned_number)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_wrap_original do |original, **kwargs|
        allow(kwargs[:whatsapp_channel]).to receive(:provider_config_changed?).and_raise(NoMethodError, 'planted 598')
        original.call(**kwargs)
      end

      create_cloud_inbox

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that reads the second whatsapp_cloud answer' do
      graph_answers(templates: templates_ok, phone_numbers: owned_number)
      plant(Whatsapp::Providers::WhatsappCloudService, :credential_check_body)

      create_cloud_inbox

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that builds the zapi request' do
      plant(Whatsapp::Providers::WhatsappZapiService, :api_instance_path_with_token)

      create_inbox(provider: 'zapi', provider_config: { instance_id: 'inst598', token: 'tok598segredo', client_token: 'ct' })

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that reads the zapi answer' do
      stub_request(:get, %r{api\.z-api\.io/instances/.+/status}).to_return(json(200, { connected: true }))
      plant(Whatsapp::Providers::WhatsappZapiService, :process_response)

      create_inbox(provider: 'zapi', provider_config: { instance_id: 'inst598', token: 'tok598segredo', client_token: 'ct' })

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that builds the baileys request' do
      plant(Whatsapp::Providers::WhatsappBaileysService, :provider_url)

      create_inbox(provider: 'baileys', provider_config: { provider_url: 'https://baileys.test', api_key: 'k' })

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that reads the baileys answer' do
      stub_request(:get, %r{baileys\.test/status/auth}).to_return(json(200, { data: { connection: 'open' } }))
      plant(Whatsapp::Providers::WhatsappBaileysService, :process_response)

      create_inbox(provider: 'baileys', provider_config: { provider_url: 'https://baileys.test', api_key: 'k' })

      expect_the_defect_to_escape
    end

    it 'escapes as itself from the code that builds the 360dialog request' do
      plant(Whatsapp::Providers::Whatsapp360DialogService, :api_base_path)

      create_inbox(provider: 'default', provider_config: { api_key: 'k' })

      expect_the_defect_to_escape
    end
  end
end
