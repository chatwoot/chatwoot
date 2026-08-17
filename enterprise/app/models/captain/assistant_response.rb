# == Schema Information
#
# Table name: captain_assistant_responses
#
#  id                :bigint           not null, primary key
#  answer            :text             not null
#  documentable_type :string
#  edited            :boolean          default(FALSE), not null
#  embedding         :vector(1536)
#  question          :string           not null
#  status            :integer          default("approved"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  assistant_id      :bigint           not null
#  documentable_id   :bigint
#
# Indexes
#
#  idx_cap_asst_resp_on_documentable                  (documentable_id,documentable_type)
#  index_captain_assistant_responses_on_account_id    (account_id)
#  index_captain_assistant_responses_on_assistant_id  (assistant_id)
#  index_captain_assistant_responses_on_status        (status)
#  vector_idx_knowledge_entries_embedding             (embedding) USING ivfflat
#
class Captain::AssistantResponse < ApplicationRecord
  self.table_name = 'captain_assistant_responses'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  belongs_to :documentable, polymorphic: true, optional: true
  has_neighbors :embedding, normalize: true

  validates :question, presence: true
  validates :answer, presence: true
  validate :assistant_belongs_to_account

  before_validation :ensure_account
  before_validation :ensure_status
  before_validation :mark_as_edited, on: :update
  after_commit :update_response_embedding

  scope :ordered, -> { order(created_at: :desc) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }
  scope :with_document, ->(document_id) { where(document_id: document_id) }

  enum status: { approved: 1 }

  def self.search(query, account_id: nil)
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(5)
  end

  def customer_visible_source_url
    documentable.customer_visible_source_url if documentable.is_a?(Captain::Document)
  end

  private

  def ensure_status
    self.status ||= :approved
  end

  def mark_as_edited
    self.edited = true if question_changed? || answer_changed?
  end

  def ensure_account
    self.account ||= assistant&.account
  end

  def assistant_belongs_to_account
    return if assistant.blank? || assistant.account_id == account_id

    errors.add(:assistant, :invalid)
  end

  def update_response_embedding
    return unless saved_change_to_question? || saved_change_to_answer? || embedding.nil?

    Captain::Llm::UpdateEmbeddingJob.perform_later(self, "#{question}: #{answer}")
  end
end
