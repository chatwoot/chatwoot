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
# Indexes
#
#  index_article_embeddings_on_embedding  (embedding) USING ivfflat
#
class ArticleEmbedding < ApplicationRecord
  belongs_to :article
  has_neighbors :embedding, normalize: true

  after_commit :update_response_embedding

  private

  def update_response_embedding
    return unless saved_change_to_term? || embedding.nil?

    Captain::Llm::UpdateEmbeddingJob.perform_later(self, term)
  end
end
