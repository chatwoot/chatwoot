module Enterprise::Concerns::Article
  extend ActiveSupport::Concern

  included do
    after_save :add_article_embedding, if: -> { saved_change_to_title? || saved_change_to_description? || saved_change_to_content? }

    def self.add_article_embedding_association
      has_many :article_embeddings, dependent: :destroy_async
    end

    add_article_embedding_association if Features::HelpcenterEmbeddingSearchService.new.feature_enabled?

    def self.vector_search(params)
      embedding = Openai::EmbeddingsService.new.get_embedding(params['query'], 'text-embedding-3-small')
      records = joins(
        :category
      ).search_by_category_slug(
        params[:category_slug]
      ).search_by_category_locale(params[:locale]).search_by_author(params[:author_id]).search_by_status(params[:status])
      filtered_article_ids = records.pluck(:id)

      # Fetch nearest neighbors and their distances, then filter directly

      # experimenting with filtering results based on result threshold
      # distance_threshold = 0.2
      # if using add the filter block to the below query
      # .filter { |ae| ae.neighbor_distance <= distance_threshold }

      article_ids = ArticleEmbedding.where(article_id: filtered_article_ids)
                                    .nearest_neighbors(:embedding, embedding, distance: 'cosine')
                                    .limit(5)
                                    .pluck(:article_id)

      # Fetch the articles by the IDs obtained from the nearest neighbors search
      where(id: article_ids)
    end
  end

  def add_article_embedding
    return unless account.feature_enabled?('help_center_embedding_search')

    Portal::ArticleIndexingJob.perform_later(self)
  end

  def generate_and_save_article_seach_terms
    terms = generate_article_search_terms
    article_embeddings.destroy_all
    terms.each { |term| article_embeddings.create!(term: term) }
  end

  def article_to_search_terms_prompt
    <<~SYSTEM_PROMPT_MESSAGE
      For the provided article content, generate potential search query keywords and snippets that can be used to generate the embeddings.
      Ensure the search terms are as diverse as possible but capture the essence of the article and are super related to the articles.
      Don't return any terms if there aren't any terms of relevance.
      Always return results in valid JSON of the following format
      {
        "search_terms": []
      }
    SYSTEM_PROMPT_MESSAGE
  end

  def generate_article_search_terms
    messages = [
      { role: 'system', content: article_to_search_terms_prompt },
      { role: 'user', content: "title: #{title} \n description: #{description} \n content: #{content}" }
    ]
    headers = { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{ENV.fetch('OPENAI_API_KEY', nil)}" }
    body = { model: 'gpt-4o', messages: messages, response_format: { type: 'json_object' } }.to_json
    Rails.logger.info "Requesting Chat GPT with body: #{body}"
    response = HTTParty.post('https://api.openai.com/v1/chat/completions', headers: headers, body: body)
    Rails.logger.info "Chat GPT response: #{response.body}"
    JSON.parse(response.parsed_response['choices'][0]['message']['content'])['search_terms']
  end
end
