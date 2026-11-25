require 'rails_helper'

RSpec.describe Whatsapp::Session::Backends::Uazapi::Client do
  subject(:client) { described_class.new(base_url: 'https://uazapi.test/', token: 'instance-token') }

  let(:errors) { Whatsapp::Session::Errors }

  # Every call resolves its host before it connects, so the test address is answered here
  # rather than left to a name server.
  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['93.184.216.34'])
  end

  it 'refuses to exist without somewhere to go and something to say' do
    expect { described_class.new(base_url: '', token: 'x') }.to raise_error(errors::InvalidConfig)
    expect { described_class.new(base_url: 'https://uazapi.test', token: '') }.to raise_error(errors::InvalidConfig)
  end

  it 'authenticates with the instance token and trims a trailing slash off the base url' do
    stub_request(:post, 'https://uazapi.test/send/text').to_return(status: 200, body: '{"messageid":"3EB0"}')

    expect(client.post('/send/text', { number: '55' })).to eq('messageid' => '3EB0')
    expect(WebMock).to have_requested(:post, 'https://uazapi.test/send/text').with(headers: { 'token' => 'instance-token' })
  end

  # The base URL is typed by whoever administers the account, and this class sends that
  # account's credentials to it and hands the answer back to the dashboard. A check on the
  # literal address cannot cover a name that resolves inward, so the destination is
  # resolved and refused here, at the moment of the call.
  it 'refuses to call an address that resolves inside the deployment' do
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['10.0.0.5'])
    stub_request(:post, 'https://uazapi.test/send/text').to_return(status: 200, body: '{}')

    expect { client.post('/send/text', { number: '55' }) }.to raise_error(errors::InvalidConfig)
    expect(WebMock).not_to have_requested(:post, 'https://uazapi.test/send/text')
  end

  # An operator running the instance next to Chatwoot is the one case the filter cannot be
  # asked about: it has no way of being told that this private address is the intended one.
  it 'calls it anyway where the operator has opened the private network' do
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['10.0.0.5'])
    stub_request(:post, 'https://uazapi.test/send/text').to_return(status: 200, body: '{"messageid":"3EB0"}')

    with_modified_env SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'true' do
      expect(client.post('/send/text', { number: '55' })).to eq('messageid' => '3EB0')
    end
  end

  # Anything not named as transport escapes as itself, and a caller that rescues this
  # layer's own errors lets it through: the pairing poll stops, and the inbox goes on
  # showing a QR that stopped being valid.
  it 'answers a closed connection and a gone route as the provider being unreachable' do
    [EOFError, Errno::ENETUNREACH, Errno::EPIPE, Net::HTTPBadResponse].each do |failure|
      stub_request(:post, 'https://uazapi.test/send/text').to_raise(failure)

      expect { client.post('/send/text', { number: '55' }) }.to raise_error(errors::ProviderUnavailable)
    end
  end

  # HTTParty carries every header it was given across a redirect, the instance token
  # among them, so a 3xx to another host would hand that credential to whoever answers
  # there.
  it 'does not follow a redirect off the private-network path' do
    allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['10.0.0.5'])
    stub_request(:post, 'https://uazapi.test/send/text').to_return(status: 302, headers: { 'Location' => 'https://evil.test/x' })
    stub_request(:post, 'https://evil.test/x').to_return(status: 200, body: '{}')

    with_modified_env SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'true' do
      expect { client.post('/send/text', { number: '55' }) }.to raise_error(errors::ProviderUnavailable)
    end

    expect(WebMock).not_to have_requested(:post, 'https://evil.test/x')
  end

  # `Net::HTTP` retries an idempotent request once by default, so the ceilings this class
  # advertises were worth half of what they read as on every `get`: measured against a
  # socket that accepts and never answers, a GET at `read_timeout: 3` took 6.0s, and 3.0s
  # once the retry was closed. One of those `get`s runs inside the pairing poll, so the
  # doubling landed on a loop that is already waiting.
  #
  # Both transports, because which one runs is decided by a deployment variable and the
  # ceiling cannot depend on that.
  describe 'the second axis of the ceiling' do
    it 'closes the retry on the filtered transport' do
      options = nil
      allow(SsrfFilter).to receive(:get) do |_uri, **kwargs|
        options = kwargs[:http_options]
        instance_double(Net::HTTPOK, code: '200', body: '{}')
      end

      client.get('/instance/status')

      expect(options).to include(max_retries: 0)
    end

    it 'closes the retry on the private-network transport' do
      options = nil
      allow(HTTParty).to receive(:get) do |_url, **kwargs|
        options = kwargs
        instance_double(HTTParty::Response, code: 200, body: '{}')
      end

      allow(Resolv).to receive(:getaddresses).with('uazapi.test').and_return(['10.0.0.5'])
      with_modified_env SAFE_FETCH_ALLOW_PRIVATE_NETWORK: 'true' do
        client.get('/instance/status')
      end

      expect(options).to include(max_retries: 0)
    end

    # A fence, not a checklist. The two examples above each hold one transport, and they
    # hold nothing about a third: this class picks its transport from a deployment
    # variable, so a call added outside `direct` and `filtered` would carry neither
    # ceiling and no example here would notice.
    it 'reaches the network in those two places and nowhere else' do
      source = File.read(Rails.root.join('app/services/whatsapp/session/backends/uazapi/client.rb'))

      expect(source.scan('HTTParty.').size).to eq(1)
      expect(source.scan('SsrfFilter.public_send').size).to eq(1)
    end
  end

  describe 'what it makes of a failure' do
    # The class decides what the caller does next: a retryable error keeps an outbound
    # message in the queue, a non-retryable one puts the reason in front of the agent.
    {
      400 => 'Whatsapp::Session::Errors::InvalidPayload',
      401 => 'Whatsapp::Session::Errors::Unauthorized',
      403 => 'Whatsapp::Session::Errors::Unauthorized',
      404 => 'Whatsapp::Session::Errors::SessionNotFound',
      405 => 'Whatsapp::Session::Errors::NotSupported',
      413 => 'Whatsapp::Session::Errors::MediaTooLarge',
      429 => 'Whatsapp::Session::Errors::RateLimited',
      500 => 'Whatsapp::Session::Errors::ProviderUnavailable',
      503 => 'Whatsapp::Session::Errors::ProviderUnavailable'
    }.each do |status, error|
      it "answers #{status} with #{error.demodulize}" do
        stub_request(:get, 'https://uazapi.test/instance/status').to_return(status: status, body: '{}')

        expect { client.get('/instance/status') }.to(raise_error { |raised| expect(raised.class.name).to eq(error) })
      end
    end

    # An unmapped 4xx is this request being wrong, and retrying it would keep a message in
    # the queue forever instead of telling the agent it failed.
    it 'treats an unmapped 4xx as a request that will not work next time either' do
      stub_request(:get, 'https://uazapi.test/instance/status').to_return(status: 409, body: '{}')

      expect { client.get('/instance/status') }.to(raise_error { |raised| expect(raised).not_to be_retryable })
    end

    it 'quotes the provider message and nothing else from the body' do
      stub_request(:get, 'https://uazapi.test/instance/status')
        .to_return(status: 405, body: { message: 'Method Not Allowed.', data: { token: 'instance-token' } }.to_json)

      expect { client.get('/instance/status') }.to raise_error(errors::NotSupported, /Method Not Allowed/) do |raised|
        expect(raised.message).not_to include('instance-token')
      end
    end

    # Measured against the live instance on 10/09/2026: a refused group description answers
    # `{"error":"Description cannot be empty"}`. This provider puts refusals under `error`
    # and reports under `message`, and reading only `message` left the operator with a bare
    # status on exactly the answers that carried a reason.
    it 'quotes the reason when the provider files it under error' do
      stub_request(:post, 'https://uazapi.test/group/updateDescription')
        .to_return(status: 400, body: { error: 'Description cannot be empty' }.to_json)

      expect { client.post('/group/updateDescription') }
        .to raise_error(errors::InvalidPayload, /Description cannot be empty/)
    end

    # Nothing to say is still nothing to say: a body with neither key must not turn into a
    # trailing colon with a blank after it.
    it 'says only what happened when the body carries no words' do
      stub_request(:get, 'https://uazapi.test/instance/status')
        .to_return(status: 400, body: { data: { token: 'instance-token' } }.to_json)

      expect { client.get('/instance/status') }.to raise_error(errors::InvalidPayload) do |raised|
        expect(raised.message).to end_with('answered 400')
      end
    end

    it 'reports a provider that does not answer as one to ask again later' do
      stub_request(:get, 'https://uazapi.test/instance/status').to_timeout

      expect { client.get('/instance/status') }.to raise_error(errors::ProviderUnavailable) do |raised|
        expect(raised).to be_retryable
      end
    end
  end
end
