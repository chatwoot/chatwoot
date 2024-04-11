class ArticleEmbedding < ApplicationRecord
  belongs_to :article
  has_neighbors :embedding, normalize: true

  before_save :update_response_embedding

  enum status: { pending: 0, active: 1 }

  private

  def update_response_embedding
    self.embedding = Openai::EmbeddingsService.new.get_embedding("#{article.title}: #{article.description} - #{article.content}")
  end
end
