class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(record, content)
    source, metadata = case record
                       when Captain::AssistantResponse
                         ['assistant_response', { assistant_id: record.assistant_id }]
                       when Captain::FaqSuggestion
                         ['faq_suggestion', { assistant_id: record.assistant_id, language: record.language }]
                       when ArticleEmbedding
                         ['help_center_article', { language: record.article.locale, article_id: record.article_id }]
                       else
                         raise ArgumentError, "Unsupported embedding record: #{record.class.name}"
                       end
    metadata[:record_type] = record.class.name
    metadata[:record_id] = record.id
    embedding = Captain::Llm::EmbeddingService.new(account_id: record.account_id).get_embedding(
      content,
      purpose: 'indexing',
      source: source,
      metadata: metadata
    )
    record.update!(embedding: embedding)
  end
end
