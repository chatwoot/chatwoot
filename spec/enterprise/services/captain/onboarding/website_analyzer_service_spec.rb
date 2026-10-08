require 'rails_helper'

RSpec.describe Captain::Onboarding::WebsiteAnalyzerService do
  let(:website_url) { 'https://example.com' }
  let(:service) { described_class.new(website_url) }
  let(:mock_crawler) { instance_double(Captain::Tools::SimplePageCrawlService) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:business_info) do
    {
      'business_name' => 'Example Corp',
      'suggested_assistant_name' => 'Alex from Example Corp',
      'description' => 'You specialize in helping customers with business solutions and support'
    }
  end
  let(:mock_response) do
    instance_double(RubyLLM::Message, content: business_info.to_json)
  end

  before do
    InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_API_KEY').update!(value: 'test-key')
    allow(Captain::Tools::SimplePageCrawlService).to receive(:new).and_return(mock_crawler)
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:with_provider_options).and_return(mock_chat)
    allow(mock_chat).to receive(:add_message).with(role: :user, content: 'Respond with valid JSON.')
    allow(mock_chat).to receive(:with_max_output_tokens).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#analyze' do
    context 'when website content is available and LLM call is successful' do
      before do
        allow(mock_crawler).to receive(:body_markdown).and_return('Welcome to Example Corp')
        allow(mock_crawler).to receive(:page_title).and_return('Example Corp - Home')
        allow(mock_crawler).to receive(:meta_description).and_return('Leading provider of business solutions')
        allow(mock_crawler).to receive(:favicon_url).and_return('https://example.com/favicon.ico')
      end

      it 'returns successful analysis with extracted business info' do
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

      it 'uses low temperature for deterministic analysis' do
        expect(mock_chat).to receive(:with_temperature).with(0.1).and_return(mock_chat)
        service.analyze
      end

      it 'uses the Responses JSON format' do
        expect(mock_chat).to receive(:with_provider_options).with({ text: { format: { type: 'json_object' } } }).and_return(mock_chat)
        service.analyze
      end

      context 'when GPT-5 Mini is configured' do
        before do
          InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_MODEL').update!(value: 'gpt-5-mini')
        end

        it 'omits temperature' do
          expect(mock_chat).not_to receive(:with_temperature)
          service.analyze
        end
      end
    end

    context 'when website content fetch raises an error' do
      before do
        allow(mock_crawler).to receive(:body_markdown).and_raise(StandardError, 'Network error')
      end

      it 'returns error response' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch website content')
      end
    end

    context 'when website content is empty' do
      before do
        allow(mock_crawler).to receive(:body_markdown).and_return('')
        allow(mock_crawler).to receive(:page_title).and_return('')
        allow(mock_crawler).to receive(:meta_description).and_return('')
      end

      it 'returns error for unavailable content' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to fetch website content')
      end
    end

    context 'when LLM call fails' do
      before do
        allow(mock_crawler).to receive(:body_markdown).and_return('Welcome to Example Corp')
        allow(mock_crawler).to receive(:page_title).and_return('Example Corp - Home')
        allow(mock_crawler).to receive(:meta_description).and_return('Leading provider of business solutions')
        allow(mock_crawler).to receive(:favicon_url).and_return('https://example.com/favicon.ico')
        allow(mock_chat).to receive(:ask).and_raise(StandardError, 'API error')
      end

      it 'returns error response with message' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API error')
      end
    end

    context 'when LLM returns invalid JSON' do
      let(:invalid_response) { instance_double(RubyLLM::Message, content: 'not valid json') }

      before do
        allow(mock_crawler).to receive(:body_markdown).and_return('Welcome to Example Corp')
        allow(mock_crawler).to receive(:page_title).and_return('Example Corp - Home')
        allow(mock_crawler).to receive(:meta_description).and_return('Leading provider of business solutions')
        allow(mock_crawler).to receive(:favicon_url).and_return('https://example.com/favicon.ico')
        allow(mock_chat).to receive(:ask).and_return(invalid_response)
      end

      it 'returns error for parsing failure' do
        result = service.analyze

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Failed to parse business information from website')
      end
    end

    context 'when URL normalization is needed' do
      let(:website_url) { 'example.com' }

      before do
        allow(mock_crawler).to receive(:body_markdown).and_return('Welcome')
        allow(mock_crawler).to receive(:page_title).and_return('Example')
        allow(mock_crawler).to receive(:meta_description).and_return('Description')
        allow(mock_crawler).to receive(:favicon_url).and_return(nil)
      end

      it 'normalizes URL by adding https prefix' do
        result = service.analyze

        expect(result[:data][:website_url]).to eq('https://example.com')
      end
    end
  end
end
