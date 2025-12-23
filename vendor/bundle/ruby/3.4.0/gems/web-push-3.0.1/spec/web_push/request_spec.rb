require 'spec_helper'

describe WebPush::Request do
  describe '#headers' do
    let(:request) { build_request }

    it { expect(request.headers['Content-Type']).to eq('application/octet-stream') }
    it { expect(request.headers['Ttl']).to eq('2419200') }
    it { expect(request.headers['Urgency']).to eq('normal') }

    describe 'from :message' do
      it 'inserts encryption headers for valid payload' do
        allow(WebPush::Encryption).to receive(:encrypt).and_return('encrypted')
        request = build_request(message: 'Hello')

        expect(request.headers['Content-Encoding']).to eq('aes128gcm')
        expect(request.headers['Content-Length']).to eq('9')
      end
    end

    describe 'from :ttl' do
      it 'can override Ttl with :ttl option with string' do
        request = build_request(ttl: '300')

        expect(request.headers['Ttl']).to eq('300')
      end

      it 'can override Ttl with :ttl option with fixnum' do
        request = build_request(ttl: 60 * 5)

        expect(request.headers['Ttl']).to eq('300')
      end
    end

    describe 'from :urgency' do
      it 'can override Urgency with :urgency option' do
        request = build_request(urgency: 'high')

        expect(request.headers['Urgency']).to eq('high')
      end
    end
  end

  describe '#build_vapid_header' do
    it 'returns the VAPID header' do
      time = Time.at(1_476_150_897)
      jwt_payload = {
        aud: 'https://fcm.googleapis.com',
        exp: time.to_i + 12 * 60 * 60,
        sub: 'mailto:sender@example.com'
      }
      jwt_header_fields = { "typ": "JWT", "alg": "ES256" }

      vapid_key = WebPush::VapidKey.from_keys(vapid_public_key, vapid_private_key)
      expect(Time).to receive(:now).and_return(time)
      expect(WebPush::VapidKey).to receive(:from_keys).with(vapid_public_key, vapid_private_key).and_return(vapid_key)
      expect(JWT).to receive(:encode).with(jwt_payload, vapid_key.curve, 'ES256', jwt_header_fields).and_return('jwt.encoded.payload')

      request = build_request
      header = request.build_vapid_header

      expect(header).to eq("vapid t=jwt.encoded.payload,k=#{vapid_public_key.delete('=')}")
    end

    it 'supports PEM format' do
      pem = WebPush::VapidKey.new.to_pem
      expect(WebPush::VapidKey).to receive(:from_pem).with(pem).and_call_original
      request = build_request(vapid: { subject: 'mailto:sender@example.com', pem: pem })
      request.build_vapid_header
    end
  end

  describe '#body' do
    it 'is set to the payload if a message is provided' do
      allow(WebPush::Encryption).to receive(:encrypt).and_return('encrypted')

      request = build_request(message: 'Hello')

      expect(request.body).to eq('encrypted')
    end

    it 'is empty string when no message is provided' do
      request = build_request

      expect(request.body).to eq('')
    end
  end

  describe '#proxy_options' do
    it 'returns an array of proxy options' do
      request = build_request(proxy: 'http://user:password@proxy_addr:8080')

      expect(request.proxy_options).to eq(['proxy_addr', 8080, 'user', 'password'])
    end

    it 'returns empty array' do
      request = build_request

      expect(request.proxy_options).to be_empty
    end
  end

  def build_request(options = {})
    subscription = {
      endpoint: endpoint,
      keys: {
        p256dh: 'p256dh',
        auth: 'auth'
      }
    }
    WebPush::Request.new(message: '', subscription: subscription, vapid: vapid_options, **options)
  end

  def endpoint
    'https://fcm.googleapis.com/gcm/send/subscription-id'
  end
end
