# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  embedding  :vector(1536)
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#
# Indexes
#
#  index_canned_responses_on_embedding  (embedding) USING ivfflat
#

class CannedResponse < ApplicationRecord
  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account
  has_neighbors :embedding, normalize: true

  after_commit :update_response_embedding

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])

    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"

    order(Arel.sql(order_clause) => :desc)
  }

  def self.semantic_search(query, limit: 5)
    return none if query.blank?

    embedding = Captain::Llm::EmbeddingService.new.get_embedding(query)
    nearest_neighbors(:embedding, embedding, distance: 'cosine').limit(limit)
  rescue StandardError => e
    Rails.logger.error("Semantic search failed: #{e.message}")
    none
  end

  private

  def update_response_embedding
    return unless saved_change_to_content? || embedding.nil?

    CannedResponseEmbeddingJob.perform_later(self)
  end
end
