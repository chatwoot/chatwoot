# == Schema Information
#
# Table name: response_sources
#
#  id                :bigint           not null, primary key
#  name              :string           not null
#  source_link       :string
#  source_model_type :string
#  source_type       :integer          default("external"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  source_model_id   :bigint
#
# Indexes
#
#  index_response_sources_on_source_model  (source_model_type,source_model_id)
#
class ResponseSource < ApplicationRecord
  enum source_type: { external: 0, kbase: 1, inbox: 2 }
  has_many :inbox_response_sources, dependent: :destroy_async
  has_many :inboxes, through: :inbox_response_sources
  belongs_to :account
  has_many :response_documents, dependent: :destroy_async
  has_many :responses, dependent: :destroy_async

  accepts_nested_attributes_for :response_documents

  def get_responses(query)
    embedding = Openai::EmbeddingsService.new.get_embedding(query)
    responses.active.nearest_neighbors(:embedding, embedding, distance: 'cosine').first(5)
  end
end
