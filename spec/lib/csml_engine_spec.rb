require 'rails_helper'

describe CsmlEngine do
  it 'raises an exception if host and api is absent' do
    expect { described_class.new }.to raise_error(StandardError)
  end

  context 'when CSML_BOT_HOST & CSML_BOT_API_KEY is present' do
    before do
      create(:installation_config, { name: 'CSML_BOT_HOST', value: 'https://csml.chatwoot.dev' })
      create(:installation_config, { name: 'CSML_BOT_API_KEY', value: 'random_api_key' })
    end

    let(:csml_request) { double }

    context 'when status is called' do
      it 'returns api response if client response is valid' do
        allow(HTTParty).to receive(:get).and_return(csml_request)
        allow(csml_request).to receive(:success?).and_return(true)
        allow(csml_request).to receive(:parsed_response).and_return({ 'engine_version': '1.11.1' })

        response = described_class.new.status

        expect(HTTParty).to have_received(:get).with('https://csml.chatwoot.dev/status')
        expect(csml_request).to have_received(:success?)
        expect(csml_request).to have_received(:parsed_response)
        expect(response).to eq({ 'engine_version': '1.11.1' })
      end

      it 'returns error if client response is invalid' do
        allow(HTTParty).to receive(:get).and_return(csml_request)
        allow(csml_request).to receive(:success?).and_return(false)
        allow(csml_request).to receive(:code).and_return(401)
        allow(csml_request).to receive(:parsed_response).and_return({ 'error': true })

        response = described_class.new.status

        expect(HTTParty).to have_received(:get).with('https://csml.chatwoot.dev/status')
        expect(csml_request).to have_received(:success?)
        expect(response).to eq({ error: { 'error': true }, status: 401 })
      end
    end

    context 'when run is called' do
      it 'returns api response if client response is valid' do
        allow(HTTParty).to receive(:post).and_return(csml_request)
        allow(SecureRandom).to receive(:uuid).and_return('xxxx-yyyy-wwww-cccc')
        allow(csml_request).to receive(:success?).and_return(true)
        allow(csml_request).to receive(:parsed_response).and_return({ 'success': true })

        response = described_class.new.run({ flow: 'default' }, { client: 'client', payload: { id: 1 }, metadata: {} })

        payload = {
          bot: { flow: 'default' },
          event: {
            request_id: 'xxxx-yyyy-wwww-cccc',
            client: 'client',
            payload: { id: 1 },
            metadata: {},
            ttl_duration: 4000
          }
        }
        expect(HTTParty).to have_received(:post)
          .with(
            'https://csml.chatwoot.dev/run', {
              body: payload.to_json,
              headers: { 'X-Api-Key' => 'random_api_key', 'Content-Type' => 'application/json' }
            }
          )
        expect(csml_request).to have_received(:success?)
        expect(csml_request).to have_received(:parsed_response)
        expect(response).to eq({ 'success': true })
      end
    end

    context 'when validate is called' do
      it 'returns api response if client response is valid' do
        allow(HTTParty).to receive(:post).and_return(csml_request)
        allow(SecureRandom).to receive(:uuid).and_return('xxxx-yyyy-wwww-cccc')
        allow(csml_request).to receive(:success?).and_return(true)
        allow(csml_request).to receive(:parsed_response).and_return({ 'success': true })

        payload = { flow: 'default' }
        response = described_class.new.validate(payload)

        expect(HTTParty).to have_received(:post)
          .with(
            'https://csml.chatwoot.dev/validate', {
              body: payload.to_json,
              headers: { 'X-Api-Key' => 'random_api_key', 'Content-Type' => 'application/json' }
            }
          )
        expect(csml_request).to have_received(:success?)
        expect(csml_request).to have_received(:parsed_response)
        expect(response).to eq({ 'success': true })
      end
    end
  end
end
