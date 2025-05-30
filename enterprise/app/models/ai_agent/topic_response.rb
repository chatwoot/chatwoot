# == Schema Information
#
# Table name: ai_agent_topic_responses
#
#  id               :bigint           not null, primary key
#  question         :string           not null
#  answer           :text             not null
#  embedding        :vector(1536)
#  topic_id         :bigint           not null
#  documentable_id  :bigint
#  account_id       :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  status           :integer          default(1), not null
#  documentable_type :string
#
# Indexes
#
#  index_ai_agent_topic_responses_on_account_id                     (account_id)
#  index_ai_agent_topic_responses_on_topic_id                       (topic_id)
#  index_ai_agent_topic_responses_on_documentable_id_and_documentable_type  (documentable_id,documentable_type)
#  vector_idx_knowledge_entries_embedding                           (embedding) USING ivfflat
#  index_ai_agent_topic_responses_on_status                         (status)
#
class AIAgent::TopicResponse < ApplicationRecord
  self.table_name = 'ai_agent_topic_responses'

  belongs_to :topic, class_name: 'AIAgent::Topic'
  belongs_to :account
  belongs_to :documentable, polymorphic: true, optional: true
  has_neighbors :embedding, normalize: true

  validates :question, presence: true
  validates :answer, presence: true

  before_validation :ensure_account
  before_validation :ensure_status
  after_commit :update_response_embedding

  scope :ordered, -> { order(created_at: :desc) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_topic, ->(topic_id) { where(topic_id: topic_id) }
  scope :with_document, ->(document_id) { where(document_id: document_id) }

  enum status: { pending: 0, approved: 1 }

  def self.search(query)
    embedding = AIAgent::Llm::EmbeddingService.new.get_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(5)
  end

  private

  def ensure_status
    self.status ||= :approved
  end

  def ensure_account
    self.account = topic&.account
  end

  def update_response_embedding
    return unless saved_change_to_question? || saved_change_to_answer? || embedding.nil?

    AIAgent::Llm::UpdateEmbeddingJob.perform_later(self, "#{question}: #{answer}")
  end
end 