require 'rails_helper'

# Simulate the prepend_mod_with behavior for testing
test_klass = Class.new(WebsiteBrandingService) do
  prepend Enterprise::WebsiteBrandingService
end

RSpec.describe Enterprise::WebsiteBrandingService do
  describe '#perform' do
    subject(:service) { test_klass.new(email) }

    let(:email) { 'user@example.com' }
    let(:api_key) { 'test-context-dev-api-key' }
    let(:endpoint) { described_class::CONTEXT_DEV_ENDPOINT }
    let(:fallback_html) { '<html><head><title>Fallback</title></head><body></body></html>' }
    let(:success_response_body) do
      {
        status: 'ok',
        code: 200,
        brand: {
          domain: 'example.com',
          title: 'Acme Corp',
          description: 'Leading tech company',
          slogan: 'We build things',
          is_nsfw: false,
          colors: [{ hex: '#FF5733', name: 'Orange Red' }],
          logos: [{ url: 'https://media.brand.dev/logo.png', type: 'icon', mode: 'light',
                    colors: [{ hex: '#FF5733', name: 'Orange Red' }],
                    resolution: { width: 256, height: 256, aspect_ratio: 1 } }],
          socials: [
            { type: 'facebook', url: 'https://facebook.com/acmecorp' },
            { type: 'instagram', url: 'https://instagram.com/acme_corp' }
          ],
          industries: {
            eic: [{ industry: 'Technology', subindustry: 'Software' }]
          }
        }
      }.to_json
    end

    before do
      stub_request(:get, 'https://example.com').to_return(status: 200, body: fallback_html,
                                                          headers: { 'content-type' => 'text/html' })
    end

    context 'when context.dev is configured and API returns success' do
      before do
        create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: api_key)
        stub_request(:get, endpoint)
          .with(query: { email: email }, headers: { 'Authorization' => "Bearer #{api_key}" })
          .to_return(status: 200, body: success_response_body, headers: { 'content-type' => 'application/json' })
      end

      it 'returns basic brand info' do
        result = service.perform

        expect(result).to include(domain: 'example.com', title: 'Acme Corp', description: 'Leading tech company',
                                  slogan: 'We build things', is_nsfw: false, email: email)
      end

      it 'returns colors, logos, socials, and industries' do
        result = service.perform

        expect(result[:colors]).to eq([{ hex: '#FF5733', name: 'Orange Red' }])
        expect(result[:logos].first[:url]).to eq('https://media.brand.dev/logo.png')
        expect(result[:socials]).to eq([{ type: 'facebook', url: 'https://facebook.com/acmecorp' },
                                        { type: 'instagram', url: 'https://instagram.com/acme_corp' }])
        expect(result[:industries]).to eq([{ industry: 'Technology', subindustry: 'Software' }])
      end
    end

    context 'when context.dev API returns an error' do
      before do
        create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: api_key)
        stub_request(:get, endpoint)
          .with(query: { email: email })
          .to_return(status: 422, body: '{"error": "FREE_EMAIL_DETECTED"}')
      end

      it 'returns nil' do
        expect(service.perform).to be_nil
      end
    end

    context 'when context.dev raises an exception' do
      before do
        create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: api_key)
        stub_request(:get, endpoint).with(query: { email: email }).to_raise(StandardError.new('connection refused'))
      end

      it 'returns nil' do
        expect(service.perform).to be_nil
      end
    end

    context 'when context.dev is not configured' do
      it 'falls back to base scraper' do
        result = service.perform
        expect(result[:title]).to eq('Fallback')
        expect(result[:industries]).to eq([])
      end
    end

    context 'when context.dev returns empty brand' do
      before do
        create(:installation_config, name: 'CONTEXT_DEV_API_KEY', value: api_key)
        stub_request(:get, endpoint)
          .with(query: { email: email })
          .to_return(status: 200, body: { status: 'ok', code: 200, brand: nil }.to_json,
                     headers: { 'content-type' => 'application/json' })
      end

      it 'returns nil' do
        expect(service.perform).to be_nil
      end
    end
  end
end
