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
  CANDIDATE_LIMIT = 10
  RESULT_LIMIT = 5
  MAX_RELEVANT_DISTANCE = 0.45
  TOPIC_DISTANCE_BOOST = 0.05

  self.table_name = 'captain_assistant_responses'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :account
  belongs_to :documentable, polymorphic: true, optional: true
  has_neighbors :embedding, normalize: true

  validates :question, presence: true
  validates :answer, presence: true

  before_validation :ensure_account
  before_validation :ensure_status
  before_validation :mark_as_edited, on: :update
  after_commit :update_response_embedding
  after_commit :enqueue_knowledge_map_rebuild, if: :knowledge_map_rebuild_required?

  scope :ordered, -> { order(created_at: :desc) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }
  scope :with_document, ->(document_id) { where(document_id: document_id) }

  enum status: { approved: 1 }

  def self.search(query, account_id: nil)
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(RESULT_LIMIT)
  end

  def self.search_relevant(query, account_id: nil, topic_faq_ids: [])
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(query)
    global_candidates = nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(CANDIDATE_LIMIT).to_a
    topic_candidates = topic_candidates_for(embedding, topic_faq_ids)

    (global_candidates + topic_candidates)
      .uniq(&:id)
      .select { |response| relevant_match?(response) }
      .sort_by { |response| relevance_score(response, topic_faq_ids) }
      .first(RESULT_LIMIT)
  end

  def self.topic_candidates_for(embedding, topic_faq_ids)
    return [] if topic_faq_ids.blank?

    where(id: topic_faq_ids)
      .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      .limit(RESULT_LIMIT)
      .to_a
  end
  private_class_method :topic_candidates_for

  def self.relevant_match?(response)
    distance = response.try(:neighbor_distance)
    distance.nil? || distance <= MAX_RELEVANT_DISTANCE
  end
  private_class_method :relevant_match?

  def self.relevance_score(response, topic_faq_ids)
    distance = response.try(:neighbor_distance).to_f
    topic_faq_ids.include?(response.id) ? distance - TOPIC_DISTANCE_BOOST : distance
  end
  private_class_method :relevance_score

  private

  def ensure_status
    self.status ||= :approved
  end

  def mark_as_edited
    self.edited = true if question_changed? || answer_changed?
  end

  def ensure_account
    self.account = assistant&.account
  end

  def update_response_embedding
    return unless saved_change_to_question? || saved_change_to_answer? || embedding.nil?

    Captain::Llm::UpdateEmbeddingJob.perform_later(self, "#{question}: #{answer}")
  end

  def enqueue_knowledge_map_rebuild
    affected_assistant_ids.each do |id|
      Captain::KnowledgeMapBuilderJob
        .set(wait: Captain::KnowledgeMapBuilderJob::REBUILD_DELAY)
        .perform_later(id)
    end
  end

  def affected_assistant_ids
    ids = [assistant_id]
    ids << assistant_id_before_last_save if saved_change_to_assistant_id?
    ids.compact.uniq
  end

  def knowledge_content_changed?
    saved_change_to_question? || saved_change_to_answer? || saved_change_to_status? || saved_change_to_assistant_id?
  end

  def knowledge_map_rebuild_required?
    previously_new_record? || destroyed? || knowledge_content_changed?
  end
end
