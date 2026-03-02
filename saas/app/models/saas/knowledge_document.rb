# frozen_string_literal: true

class Saas::KnowledgeDocument < ApplicationRecord
  self.table_name = 'knowledge_documents'

  has_neighbors :embedding

  belongs_to :knowledge_base, class_name: 'Saas::KnowledgeBase'
  belongs_to :account, class_name: '::Account'

  enum :source_type, { file_upload: 0, url: 1, text: 2 }
  enum :status, { pending: 0, processing: 1, ready: 2, error: 3 }

  validates :title, presence: true, length: { maximum: 500 }

  scope :ready,      -> { where(status: :ready) }
  scope :pending,    -> { where(status: :pending) }
  scope :processing, -> { where(status: :processing) }
  scope :errored,    -> { where(status: :error) }

  # Nearest-neighbour search over ready documents in a knowledge base
  def self.search(query_embedding, limit: 5)
    ready.nearest_neighbors(:embedding, query_embedding, distance: :cosine).first(limit)
  end
end
