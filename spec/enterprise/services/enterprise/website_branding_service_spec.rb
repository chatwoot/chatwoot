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
                                 whatsapp: '1234567890',
                                 line: nil,
                                 facebook: 'acmecorp',
                                 instagram: 'acme_corp',
                                 telegram: 'acmecorp',
                                 tiktok: '@acmetok'
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

    context 'when branding and links are missing from response' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        partial_response = {
          success: true,
          data: {
            json: { business_name: 'Acme Corp', language: 'en', industry_category: 'Technology' }
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: partial_response, headers: { 'content-type' => 'application/json' })
      end

      it 'returns nil for branding and social handles' do
        result = described_class.lookup(url)

        expect(result[:business_name]).to eq('Acme Corp')
        expect(result[:branding]).to eq({ logo: nil, favicon: nil, primary_color: nil })
        expect(result[:social_handles]).to eq({ whatsapp: nil, line: nil, facebook: nil, instagram: nil, telegram: nil, tiktok: nil })
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
        result = described_class.lookup(url)
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
        result = described_class.lookup(url)
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
        result = described_class.lookup(url)
        expect(result[:social_handles][:facebook]).to be_nil
        expect(result[:social_handles][:instagram]).to be_nil
      end
    end

    context 'when links contain no social media URLs' do
      before do
        create(:installation_config, name: 'CAPTAIN_FIRECRAWL_API_KEY', value: api_key)
        response = {
          success: true,
          data: {
            json: { business_name: 'Acme Corp' },
            links: ['https://example.com/about', 'https://example.com/blog', 'https://docs.example.com']
          }
        }.to_json
        stub_request(:post, scrape_endpoint)
          .to_return(status: 200, body: response, headers: { 'content-type' => 'application/json' })
      end

      it 'returns nil for all social handles' do
        result = described_class.lookup(url)
        expect(result[:social_handles].values).to all(be_nil)
      end
    end
  end
end
