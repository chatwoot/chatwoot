require 'rails_helper'

RSpec.describe Enterprise::WebsiteBrandingService do
  describe '.lookup' do
    let(:url) { 'https://example.com' }
    let(:api_key) { 'test-firecrawl-api-key' }
    let(:scrape_endpoint) { described_class::FIRECRAWL_SCRAPE_ENDPOINT }
    let(:success_response_body) do
      {
        success: true,
        data: {
          json: {
            business_name: 'Acme Corp',
            language: 'en',
            industry_category: 'Technology',
            whatsapp_number: '+1234567890',
            line_handle: nil,
            facebook_handle: 'acmecorp',
            instagram_handle: 'acme_corp',
            telegram_handle: nil,
            tiktok_handle: ''
          },
          branding: {
            images: {
              logo: 'https://example.com/logo.png',
              favicon: 'https://example.com/favicon.png'
            },
            colors: {
              primary: '#FF5733'
            }
          }
        }
      }.to_json
    end

    context 'when firecrawl is configured and API returns success' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint)
          .with(headers: { 'Authorization' => "Bearer #{api_key}", 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: success_response_body, headers: { 'content-type' => 'application/json' })
      end

      it 'returns business info and branding' do
        result = described_class.lookup(url)

        expect(result).to eq({
                               business_name: 'Acme Corp',
                               language: 'en',
                               industry_category: 'Technology',
                               social_handles: {
                                 whatsapp: '+1234567890',
                                 line: nil,
                                 facebook: 'acmecorp',
                                 instagram: 'acme_corp',
                                 telegram: nil,
                                 tiktok: nil
                               },
                               branding: {
                                 logo: 'https://example.com/logo.png',
                                 favicon: 'https://example.com/favicon.png',
                                 primary_color: '#FF5733'
                               }
                             })
      end
    end

    context 'when firecrawl is configured and API returns an error' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint)
          .to_return(status: 422, body: '{"error": "Invalid URL"}', headers: {})
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/API Error/)
        expect(described_class.lookup(url)).to be_nil
      end
    end

    context 'when an exception is raised during the request' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint).to_raise(StandardError.new('connection refused'))
      end

      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with('[WebsiteBranding] connection refused')
        expect(described_class.lookup(url)).to be_nil
      end
    end

    context 'when firecrawl is not configured' do
      it 'returns nil without making an API call' do
        expect(HTTParty).not_to receive(:post)
        expect(described_class.lookup(url)).to be_nil
      end
    end

    context 'when URL has no scheme' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        stub_request(:post, scrape_endpoint)
          .with { |request| JSON.parse(request.body)['url'] == 'https://example.com' }
          .to_return(status: 200, body: success_response_body, headers: { 'content-type' => 'application/json' })
      end

      it 'normalizes the URL by prepending https://' do
        result = described_class.lookup('example.com')
        expect(result[:business_name]).to eq('Acme Corp')
      end
    end

    context 'when brand_identity is missing from response' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        partial_response = {
          success: true,
          data: {
            json: {
              business_name: 'Acme Corp',
              language: 'en',
              industry_category: 'Technology'
            }
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: partial_response, headers: { 'content-type' => 'application/json' })
      end

      it 'returns nil for branding values but populates the rest' do
        result = described_class.lookup(url)

        expect(result[:business_name]).to eq('Acme Corp')
        expect(result[:branding]).to eq({ logo: nil, favicon: nil, primary_color: nil })
      end
    end
  end
end
