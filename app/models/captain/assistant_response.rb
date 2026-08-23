# == Schema Information
#
# Table name: captain_assistant_responses
#
#  id                :bigint           not null, primary key
#  answer            :text             not null
#  documentable_type :string
#  edited            :boolean          default(FALSE), not null
#  embedding         :vector(1024)
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
#  idx_cap_asst_resp_on_documentable                   (documentable_id,documentable_type)
#  index_captain_assistant_responses_on_account_id     (account_id)
#  index_captain_assistant_responses_on_answer_trgm    (answer) USING gin
#  index_captain_assistant_responses_on_assistant_id   (assistant_id)
#  index_captain_assistant_responses_on_question_trgm  (question) USING gin
#  index_captain_assistant_responses_on_status         (status)
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

  # Cosine similarity threshold: unrelated chunks are never surfaced to the LLM.
  DISTANCE_THRESHOLD = 0.3
  SEARCH_LIMIT = 5
  # Trigram word-similarity threshold for the keyword layer. High enough to only
  # surface genuine exact-token (SKU / promo-code / part-number) matches while
  # ignoring weak, coincidental overlaps.
  KEYWORD_MATCH_THRESHOLD = 0.35
  # Upper bound on how many query tokens are used for keyword matching, so a
  # long sentence never builds an oversized SQL expression.
  KEYWORD_TOKEN_LIMIT = 5

  # Hybrid search: exact keyword matches (SKUs, codes, part numbers) rank first,
  # cosine fills in semantically similar answers for conversational queries.
  # Scoping is mandatory so a lookup can never leak responses across assistants
  # or accounts; cross-tenant leakage is impossible when either `assistant_id`
  # or `account_id` must be provided. The embedding column carries no ANN index,
  # so `nearest_neighbors` performs a brute-force cosine scan with perfect
  # recall below ~5k rows. Returns an array of records, keyword matches first,
  # with documentable eager-loaded.
  def self.search(query, assistant_id: nil, account_id: nil)
    raise ArgumentError, 'assistant_id or account_id is required' if assistant_id.blank? && account_id.blank?

    keyword_results = keyword_search(query, assistant_id: assistant_id, account_id: account_id)
    cosine_results = cosine_search(query, account_id: account_id, assistant_id: assistant_id)
    merge_search_results(keyword_results, cosine_results)
  end

  # Deterministic keyword layer: finds responses whose question or answer
  # contains any of the query's tokens with high trigram word-similarity. This
  # is what makes exact codes/SKUs retrievable even when their meaning is
  # unrelated to the surrounding FAQ text.
  def self.keyword_search(query, assistant_id: nil, account_id: nil, limit: SEARCH_LIMIT)
    tokens = query.to_s.scan(/[[:alnum:]]+/).uniq.first(KEYWORD_TOKEN_LIMIT)
    return [] if tokens.empty?

    quoted_tokens = tokens.map { |token| connection.quote(token) }
    score_expressions = quoted_tokens.map do |token|
      "GREATEST(word_similarity(#{token}, question), word_similarity(#{token}, answer))"
    end
    match_clause = score_expressions.map { |expression| "#{expression} >= #{KEYWORD_MATCH_THRESHOLD}" }.join(' OR ')
    rank_expression = score_expressions.join(' + ')

    scoped_search(assistant_id, account_id)
      .where(match_clause)
      .order(Arel.sql("#{rank_expression} DESC, created_at DESC"))
      .limit(limit)
      .includes(:documentable)
      .to_a
  end

  def self.cosine_search(query, assistant_id: nil, account_id: nil)
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(query)
    scoped_search(assistant_id, account_id)
      .nearest_neighbors(:embedding, embedding, distance: 'cosine')
      .limit(SEARCH_LIMIT)
      .includes(:documentable)
      .select { |record| record.neighbor_distance < DISTANCE_THRESHOLD }
  end

  def self.scoped_search(assistant_id, account_id)
    scoped = all
    scoped = scoped.by_assistant(assistant_id) if assistant_id.present?
    scoped = scoped.by_account(account_id) if account_id.present?
    scoped
  end

  # Keyword matches lead, cosine fills gaps; results are de-duplicated by id and
  # capped at SEARCH_LIMIT so the prompt never receives more than a few sources.
  def self.merge_search_results(keyword_results, cosine_results)
    seen_ids = {}
    (keyword_results + cosine_results).each_with_object([]) do |record, combined|
      next if seen_ids[record.id]

      seen_ids[record.id] = true
      combined << record
      break if combined.size >= SEARCH_LIMIT
    end
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
