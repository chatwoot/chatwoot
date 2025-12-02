require 'rails_helper'

RSpec.describe Captain::Onboarding::WebsiteAnalyzerService do
  let(:website_url) { 'https://example.com' }
  let(:service) { described_class.new(website_url) }
  let(:mock_crawler) { instance_double(Captain::Tools::SimplePageCrawlService) }
  let(:mock_client) { instance_double(OpenAI::Client) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Captain::Tools::SimplePageCrawlService).to receive(:new).and_return(mock_crawler)
    allow(service).to receive(:client).and_return(mock_client)
    allow(service).to receive(:model).and_return('gpt-3.5-turbo')
  end

  describe '#analyze' do
    context 'when website content is available and OpenAI call is successful' do
      let(:openai_response) do
        {
          'choices' => [{
            'message' => {
              'content' => {
                'business_name' => 'Example Corp',
                'suggested_assistant_name' => 'Alex from Example Corp',
                'description' => 'You specialize in helping customers with business solutions and support'
              }.to_json
            }
          }]
        }
      end

      before do
        allow(mock_crawler).to receive(:body_text_content).and_return('Welcome to Example Corp')
        allow(mock_crawler).to receive(:page_title).and_return('Example Corp - Home')
        allow(mock_crawler).to receive(:meta_description).and_return('Leading provider of business solutions')
        allow(mock_crawler).to receive(:favicon_url).and_return('https://example.com/favicon.ico')
        allow(mock_client).to receive(:chat).and_return(openai_response)
      end

      it 'returns success' do
        result = service.analyze

        expect(result[:success]).to be true
        expect(result[:data]).to include(
          business_name: 'Example Corp',
          suggested_assistant_name: 'Alex from Example Corp',
          description: 'You specialize in helping customers with business solutions and support',
          website_url: website_url,
          favicon_url: 'https://example.com/favicon.ico'
        )
      end
    end

    context 'when website content is errored' do
      before do
        allow(mock_crawler).to receive(:body_text_content).and_raise(StandardError, 'Network error')
      end

      it 'returns error' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch website content')
      end
    end

    context 'when website content is unavailable' do
      before do
        allow(mock_crawler).to receive(:body_text_content).and_return('')
        allow(mock_crawler).to receive(:page_title).and_return('')
        allow(mock_crawler).to receive(:meta_description).and_return('')
      end

      it 'returns error' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch website content')
      end
    end

    context 'when OpenAI error' do
      before do
        allow(mock_crawler).to receive(:body_text_content).and_return('Welcome to Example Corp')
        allow(mock_crawler).to receive(:page_title).and_return('Example Corp - Home')
        allow(mock_crawler).to receive(:meta_description).and_return('Leading provider of business solutions')
        allow(mock_crawler).to receive(:favicon_url).and_return('https://example.com/favicon.ico')
        allow(mock_client).to receive(:chat).and_raise(StandardError, 'API error')
      end

      it 'returns error' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API error')
      end
    end
  end
end
