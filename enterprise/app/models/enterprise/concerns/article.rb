module Enterprise::Concerns::Article
  extend ActiveSupport::Concern

  SEARCH_TERMS_FEATURE = 'help_center_article_generation'
  SEARCH_TERMS_SCHEMA = {
    name: 'article_search_terms',
    schema: {
      type: 'object',
      properties: {
        search_terms: {
          type: 'array',
          items: { type: 'string' }
        }
      },
      required: %w[search_terms],
      additionalProperties: false
    },
    strict: true
  }.freeze

  included do
    after_save :add_article_embedding, if: -> { saved_change_to_title? || saved_change_to_description? || saved_change_to_content? }

    def self.add_article_embedding_association
      has_many :article_embeddings, dependent: :destroy_async
    end

    add_article_embedding_association

    def self.vector_search(params)
      embedding = Captain::Llm::EmbeddingService.new(account_id: params[:account_id]).get_embedding(params['query'])
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

      limit = params.key?(:limit) ? params[:limit] : 5

      article_embeddings = ArticleEmbedding.where(article_id: filtered_article_ids)
                                           .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      article_embeddings = article_embeddings.limit(limit) if limit.present?
      article_ids = article_embeddings.pluck(:article_id)

      # Fetch the articles by the IDs obtained from the nearest neighbors search
      where(id: article_ids).in_order_of(:id, article_ids)
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

    response = responses_client.create(
      model: search_terms_route[:model],
      messages: messages,
      schema: SEARCH_TERMS_SCHEMA,
      reasoning_effort: search_terms_route[:reasoning_effort],
      metadata: {
        account_id: account_id,
        article_id: id,
        feature: 'article_search_terms'
      }
    )

    JSON.parse(response[:message])['search_terms']
  end

  private

  def search_terms_route
    @search_terms_route ||= Llm::FeatureRouter.resolve(feature: SEARCH_TERMS_FEATURE, account: account)
  end

  def responses_client
    @responses_client ||= Llm::ResponsesClient.new(api_key: openai_api_key, api_base: openai_api_base)
  end

  def openai_api_key
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence || raise(I18n.t('captain.api_key_missing'))
  end

  def openai_api_base
    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || 'https://api.openai.com/'
    endpoint.chomp('/')
  end
end
