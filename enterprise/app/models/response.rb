# == Schema Information
#
# Table name: responses
#
#  id                   :bigint           not null, primary key
#  answer               :text             not null
#  embedding            :vector(1536)
#  question             :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  response_document_id :bigint
#
# Indexes
#
#  index_responses_on_embedding             (embedding) USING ivfflat
#  index_responses_on_response_document_id  (response_document_id)
#
class Response < ApplicationRecord
  belongs_to :response_document
  belongs_to :account
  has_neighbors :embedding, normalize: true

  before_save :update_response_embedding

  def self.search(query)
    embedding = Openai::EmbeddingsService.new.get_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: 'cosine').first(5)
  end

  private

  def update_response_embedding
    self.embedding = Openai::EmbeddingsService.new.get_embedding("#{question}: #{answer}")
  end
end
