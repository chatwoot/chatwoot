require 'rails_helper'

RSpec.describe Article do
  describe '#generate_article_search_terms' do
    it 'uses the OpenAI-only key and endpoint for search term generation' do
      article = create(:article, title: 'Refund policy', description: 'Refund terms', content: 'Refunds are processed in 5 days')
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://openrouter.ai/api')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', 'openai-key')
      stub_request(:post, Llm::OpenAiConfig.chat_completions_url)
        .with(headers: { 'Authorization' => 'Bearer openai-key' })
        .to_return(
          status: 200,
          body: {
            choices: [
              { message: { content: { search_terms: ['refund policy'] }.to_json } }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(article.generate_article_search_terms).to eq(['refund policy'])
    end

    it 'fails clearly before the HTTP call when the OpenAI-only key is missing' do
      article = create(:article, title: 'Refund policy', description: 'Refund terms', content: 'Refunds are processed in 5 days')
      set_installation_config('CAPTAIN_LLM_PROVIDER', 'openrouter')
      set_installation_config('CAPTAIN_OPEN_AI_ENDPOINT', 'https://openrouter.ai/api')
      set_installation_config('CAPTAIN_OPEN_AI_API_KEY', 'provider-key')
      set_installation_config('CAPTAIN_EMBEDDING_API_KEY', '')

      expect { article.generate_article_search_terms }
        .to raise_error(
          Llm::ConfigurationError,
          'An OpenAI API key is required for article search term generation.'
        )
      expect(WebMock).not_to have_requested(:post, Llm::OpenAiConfig.chat_completions_url)
    end
  end
end
