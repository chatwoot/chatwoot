# frozen_string_literal: true

class Saas::KnowledgeBase < ApplicationRecord
  self.table_name = 'knowledge_bases'

  belongs_to :account
  belongs_to :ai_agent, class_name: 'Saas::AiAgent'

  has_many :knowledge_documents, class_name: 'Saas::KnowledgeDocument', dependent: :destroy_async

  enum :status, { active: 0, processing: 1, error: 2 }

  validates :name, presence: true, length: { maximum: 255 }

  scope :active, -> { where(status: :active) }

  # Count of documents that are ready for search
  def ready_documents_count
    knowledge_documents.ready.count
  end

  # Total chunks across all documents
  def total_chunks
    knowledge_documents.ready.sum(:chunk_count)
  end
end
