require 'spec_helper'

describe WebPush do
  it 'has a version number' do
    expect(WebPush::VERSION).not_to be nil
  end

  shared_examples 'web push protocol standard error handling' do
    it 'raises InvalidSubscription if the API returns a 404 Error' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 404, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::InvalidSubscription)
    end

    it 'raises ExpiredSubscription if the API returns a 410 Error' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 410, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::ExpiredSubscription)
    end

    it 'raises Unauthorized if the API returns a 401 Error, a 403 Error or 400 with specific message' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 401, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::Unauthorized)

      stub_request(:post, expected_endpoint)
        .to_return(status: 403, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::Unauthorized)

      stub_request(:post, expected_endpoint)
        .to_return(status: [400, 'UnauthorizedRegistration'], body: '', headers: {})
      expect { subject }.to raise_error(WebPush::Unauthorized)
    end

    it 'raises PayloadTooLarge if the API returns a 413 Error' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 413, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::PayloadTooLarge)
    end

    it 'raises TooManyRequests if the API returns a 429 Error' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 429, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::TooManyRequests)
    end

    it 'raises PushServiceError if the API returns a 5xx Error' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 500, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::PushServiceError)

      stub_request(:post, expected_endpoint)
        .to_return(status: 503, body: '', headers: {})
      expect { subject }.to raise_error(WebPush::PushServiceError)
    end

    it 'raises ResponseError for unsuccessful status code by default' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 401, body: '', headers: {})

      expect { subject }.to raise_error(WebPush::ResponseError)
    end

    it 'supplies the original status code on the ResponseError' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 401, body: 'Oh snap', headers: {})

      expect { subject }.to raise_error { |error|
        expect(error).to be_a(WebPush::ResponseError)
        expect(error.response.code).to eq '401'
        expect(error.response.body).to eq 'Oh snap'
      }
    end

    it 'sets the error message to be the host + stringified response' do
      stub_request(:post, expected_endpoint)
        .to_return(status: 401, body: 'Oh snap', headers: {})

      host = URI.parse(expected_endpoint).host

      expect { subject }.to raise_error { |error|
        expect(error.message).to eq(
          "host: #{host}, #<Net::HTTPUnauthorized 401  readbody=true>\nbody:\nOh snap"
        )
      }
    end

    it 'raises exception on error by default' do
      stub_request(:post, expected_endpoint).to_raise(StandardError)

      expect { subject }.to raise_error(StandardError)
    end
  end

  shared_examples 'request headers with VAPID' do
    let(:message) { JSON.generate(body: 'body') }
    let(:p256dh) { 'BN4GvZtEZiZuqFxSKVZfSfluwKBD7UxHNBmWkfiZfCtgDE8Bwh-_MtLXbBxTBAWH9r7IPKL0lhdcaqtL1dfxU5E=' }
    let(:auth) { 'Q2BoAjC09xH3ywDLNJr-dA==' }
    let(:payload) { "encrypted" }
    let(:expected_body) { payload }
    let(:expected_headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Encoding' => 'aes128gcm',
        'Content-Type' => 'application/octet-stream',
        'Ttl' => '2419200',
        'Urgency' => 'normal',
        'User-Agent' => 'Ruby'
      }
    end

    let(:vapid_header) { "vapid t=jwt.encoded.payload,k=#{vapid_public_key.delete('=')}" }

    before do
      allow(WebPush::Encryption).to receive(:encrypt).and_return(payload)
      allow(JWT).to receive(:encode).and_return('jwt.encoded.payload')
    end

    subject do
      WebPush.payload_send(
        message: message,
        endpoint: endpoint,
        p256dh: p256dh,
        auth: auth,
        vapid: vapid_options
      )
    end

    it 'calls the relevant service with the correct headers' do
      expect(WebPush::Encryption).to receive(:encrypt).and_return(payload)

      expected_headers['Authorization'] = vapid_header

      stub_request(:post, expected_endpoint)
        .with(body: expected_body, headers: expected_headers)
        .to_return(status: 201, body: '', headers: {})

      result = subject

      expect(result).to be_a(Net::HTTPCreated)
      expect(result.code).to eql('201')
    end

    include_examples 'web push protocol standard error handling'

    it 'message is optional' do
      expect(WebPush::Encryption).to_not receive(:encrypt)

      expected_headers.delete('Crypto-Key')
      expected_headers.delete('Content-Encoding')
      expected_headers.delete('Encryption')

      stub_request(:post, expected_endpoint)
        .with(body: nil, headers: expected_headers)
        .to_return(status: 201, body: '', headers: {})

      WebPush.payload_send(endpoint: endpoint)
    end

    it 'vapid options are optional' do
      expect(WebPush::Encryption).to receive(:encrypt).and_return(payload)

      expected_headers.delete('Crypto-Key')
      expected_headers.delete('Authorization')

      stub_request(:post, expected_endpoint)
        .with(body: expected_body, headers: expected_headers)
        .to_return(status: 201, body: '', headers: {})

      result = WebPush.payload_send(
        message: message,
        endpoint: endpoint,
        p256dh: p256dh,
        auth: auth
      )

      expect(result).to be_a(Net::HTTPCreated)
      expect(result.code).to eql('201')
    end
  end

  context 'chrome FCM endpoint' do
    let(:endpoint) { 'https://fcm.googleapis.com/gcm/send/subscription-id' }
    let(:expected_endpoint) { endpoint }

    include_examples 'request headers with VAPID'
  end

  context 'firefox endpoint' do
    let(:endpoint) { 'https://updates.push.services.mozilla.com/push/v1/subscription-id' }
    let(:expected_endpoint) { endpoint }

    include_examples 'request headers with VAPID'
  end

  context 'chrome endpoint: request headers without VAPID' do
    let(:endpoint) { 'https://fcm.googleapis.com/fcm/subscription-id' }
    let(:expected_endpoint) { 'https://fcm.googleapis.com/fcm/subscription-id' }

    let(:message) { JSON.generate(body: 'body') }
    let(:p256dh) { 'BN4GvZtEZiZuqFxSKVZfSfluwKBD7UxHNBmWkfiZfCtgDE8Bwh-_MtLXbBxTBAWH9r7IPKL0lhdcaqtL1dfxU5E=' }
    let(:auth) { 'Q2BoAjC09xH3ywDLNJr-dA==' }
    let(:payload) { "encrypted" }
    let(:expected_body) { payload }
    let(:expected_headers) do
      {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Content-Encoding' => 'aes128gcm',
        'Content-Type' => 'application/octet-stream',
        'Ttl' => '2419200',
        'Urgency' => 'normal',
        'User-Agent' => 'Ruby'
      }
    end

    let(:subscription) {}

    before do
      allow(WebPush::Encryption).to receive(:encrypt).and_return(payload)
    end

    subject { WebPush.payload_send(message: message, endpoint: endpoint, p256dh: p256dh, auth: auth) }

    it 'calls the relevant service with the correct headers' do
      expect(WebPush::Encryption).to receive(:encrypt).and_return(payload)

      stub_request(:post, expected_endpoint)
        .with(body: expected_body, headers: expected_headers)
        .to_return(status: 201, body: '', headers: {})

      result = subject

      expect(result).to be_a(Net::HTTPCreated)
      expect(result.code).to eql('201')
    end

    include_examples 'web push protocol standard error handling'

    it 'message and encryption keys are optional' do
      expect(WebPush::Encryption).to_not receive(:encrypt)

      expected_headers.delete('Content-Encoding')

      stub_request(:post, expected_endpoint)
        .with(body: nil, headers: expected_headers)
        .to_return(status: 201, body: '', headers: {})

      WebPush.payload_send(endpoint: endpoint)
    end
  end
end
