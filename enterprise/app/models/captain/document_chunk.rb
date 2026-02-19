# == Schema Information
#
# Table name: captain_document_chunks
#
#  id           :bigint           not null, primary key
#  content      :text             not null
#  context      :text
#  embedding    :vector(1536)
#  position     :integer          not null
#  searchable   :tsvector
#  token_count  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  assistant_id :bigint           not null
#  document_id  :bigint           not null
#
# Indexes
#
#  index_captain_document_chunks_on_account_id_and_assistant_id  (account_id,assistant_id)
#  index_captain_document_chunks_on_document_id                  (document_id)
#  index_captain_document_chunks_on_document_id_and_position     (document_id,position) UNIQUE
#  index_captain_document_chunks_on_embedding                    (embedding) USING ivfflat
#  index_captain_document_chunks_on_searchable                   (searchable) USING gin
#
class Captain::DocumentChunk < ApplicationRecord
  self.table_name = 'captain_document_chunks'

  belongs_to :document, class_name: 'Captain::Document'
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account

  has_neighbors :embedding, normalize: true

  validates :content, presence: true
  validates :position, presence: true
  validates :position, uniqueness: { scope: :document_id }
end
