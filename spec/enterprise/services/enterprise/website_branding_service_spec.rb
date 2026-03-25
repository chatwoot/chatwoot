require 'rails_helper'

# Simulate the prepend_mod_with behavior for testing
test_klass = Class.new(WebsiteBrandingService) do
  prepend Enterprise::WebsiteBrandingService
end

RSpec.describe Enterprise::WebsiteBrandingService do
  describe '#perform' do
    subject(:service) { test_klass.new(url) }

    let(:url) { 'https://example.com' }
    let(:api_key) { 'test-firecrawl-api-key' }
    let(:scrape_endpoint) { described_class::FIRECRAWL_SCRAPE_ENDPOINT }
    let(:fallback_html) { '<html lang="en"><head><title>Fallback</title></head><body></body></html>' }
    let(:success_response_body) do
      {
        success: true,
        data: {
          json: {
            business_name: 'Acme Corp',
            language: 'en',
            industry_category: 'Technology'
          },
          branding: {
            images: { logo: 'https://example.com/logo.png', favicon: 'https://example.com/favicon.png' },
            colors: { primary: '#FF5733' }
          },
          links: [
            'https://example.com/about',
            'https://facebook.com/acmecorp',
            'https://instagram.com/acme_corp',
            'https://wa.me/1234567890',
            'https://t.me/acmecorp',
            'https://tiktok.com/@acmetok'
          ]
        }
      }.to_json
    end

    before do
      stub_request(:get, url).to_return(status: 200, body: fallback_html, headers: { 'content-type' => 'text/html' })
    end

    context 'when firecrawl is configured and API returns success' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint)
          .with(headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: success_response_body, headers: { 'content-type' => 'application/json' })
      end

      it 'returns business info and branding from firecrawl' do
        result = service.perform

        expect(result).to eq({
                               business_name: 'Acme Corp',
                               language: 'en',
                               industry_category: 'Technology',
                               social_handles: {
                                 whatsapp: '1234567890',
                                 line: nil,
                                 facebook: 'acmecorp',
                                 instagram: 'acme_corp',
                                 telegram: 'acmecorp',
                                 tiktok: '@acmetok'
                               },
                               branding: {
                                 favicon: 'https://example.com/favicon.png',
                                 primary_color: '#FF5733'
                               }
                             })
      end
    end

    context 'when firecrawl API returns an error' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint)
          .to_return(status: 422, body: '{"error": "Invalid URL"}', headers: {})
      end

      it 'falls back to basic scrape' do
        result = service.perform
        expect(result[:business_name]).to eq('Fallback')
        expect(result[:industry_category]).to be_nil
      end
    end

    context 'when firecrawl raises an exception' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint).to_raise(StandardError.new('connection refused'))
      end

      it 'falls back to basic scrape' do
        result = service.perform
        expect(result[:business_name]).to eq('Fallback')
      end
    end

    context 'when firecrawl is not configured' do
      it 'uses basic scrape' do
        expect(HTTParty).not_to receive(:post)
        result = service.perform
        expect(result[:business_name]).to eq('Fallback')
      end
    end

    context 'when WhatsApp link uses api.whatsapp.com format' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        response = {
          success: true,
          data: {
            json: { business_name: 'Acme Corp' },
            links: ['https://api.whatsapp.com/send?phone=5511999999999&text=Hello']
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: response, headers: { 'content-type' => 'application/json' })
      end

      it 'extracts phone number from query param' do
        result = service.perform
        expect(result[:social_handles][:whatsapp]).to eq('5511999999999')
      end
    end

    context 'when WhatsApp link uses wa.me format' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        response = {
          success: true,
          data: {
            json: { business_name: 'Acme Corp' },
            links: ['https://wa.me/+5511999999999']
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: response, headers: { 'content-type' => 'application/json' })
      end

      it 'extracts phone number from path' do
        result = service.perform
        expect(result[:social_handles][:whatsapp]).to eq('5511999999999')
      end
    end

    context 'when links contain lookalike domains' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        response = {
          success: true,
          data: {
            json: { business_name: 'Acme Corp' },
            links: ['https://notfacebook.com/page', 'https://fakeinstagram.com/user']
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: response, headers: { 'content-type' => 'application/json' })
      end

      it 'does not match lookalike domains' do
        result = service.perform
        expect(result[:social_handles][:facebook]).to be_nil
        expect(result[:social_handles][:instagram]).to be_nil
      end
    end
  end
end
