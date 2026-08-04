require 'rails_helper'

RSpec.describe Captain::Llm::UpdateEmbeddingJob do
  let(:account) { build_stubbed(:account) }
  let(:assistant) { build_stubbed(:captain_assistant, account: account) }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }
  let(:embedding) { Array.new(1536, 0.1) }

  before do
    allow(Captain::Llm::EmbeddingService).to receive(:new).with(account_id: account.id).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_return(embedding)
  end

  it 'identifies approved assistant response indexing' do
    record = build_stubbed(:captain_assistant_response, account: account, assistant: assistant)
    allow(record).to receive(:update!)

    described_class.perform_now(record, 'question: answer')

    expect(embedding_service).to have_received(:get_embedding).with(
      'question: answer',
      purpose: 'indexing',
      source: 'assistant_response',
      metadata: {
        assistant_id: assistant.id,
        record_type: 'Captain::AssistantResponse',
        record_id: record.id
      }
    )
  end

  it 'identifies FAQ suggestion indexing and includes its language' do
    record = Captain::FaqSuggestion.new(
      id: 11,
      account: account,
      assistant: assistant,
      question: 'Question',
      answer: 'Answer',
      language: 'fr'
    )
    allow(record).to receive(:update!)

    described_class.perform_now(record, 'question: answer')

    expect(embedding_service).to have_received(:get_embedding).with(
      'question: answer',
      purpose: 'indexing',
      source: 'faq_suggestion',
      metadata: {
        assistant_id: assistant.id,
        language: 'fr',
        record_type: 'Captain::FaqSuggestion',
        record_id: record.id
      }
    )
  end

  it 'identifies help center article indexing and includes its language' do
    article = build_stubbed(:article, account: account, locale: 'pt')
    record = ArticleEmbedding.new(id: 12, article: article, term: 'search term')
    allow(record).to receive(:update!)

    described_class.perform_now(record, 'search term')

    expect(embedding_service).to have_received(:get_embedding).with(
      'search term',
      purpose: 'indexing',
      source: 'help_center_article',
      metadata: {
        language: 'pt',
        article_id: article.id,
        record_type: 'ArticleEmbedding',
        record_id: record.id
      }
    )
  end
end
