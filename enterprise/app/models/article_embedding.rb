# == Schema Information
#
# Table name: article_embeddings
#
#  id         :bigint           not null, primary key
#  embedding  :vector(1536)
#  term       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#
class ArticleEmbedding < ApplicationRecord
  belongs_to :article
  has_neighbors :embedding, normalize: true

  before_save :update_response_embedding

  private

  def update_response_embedding
    self.embedding = Openai::EmbeddingsService.new.get_embedding(term, 'text-embedding-3-small')
  end
end
