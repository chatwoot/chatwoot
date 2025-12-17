# == Schema Information
#
# Table name: canned_responses
#
#  id         :integer          not null, primary key
#  content    :text
#  short_code :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :integer          not null
#

class CannedResponse < ApplicationRecord
  validates :content, presence: true
  validates :short_code, presence: true
  validates :account, presence: true
  validates :short_code, uniqueness: { scope: :account_id }

  belongs_to :account

  # ZeroDB vector indexing hooks
  after_create :index_async
  after_update :reindex_async
  after_destroy :remove_from_index_async

  scope :order_by_search, lambda { |search|
    short_code_starts_with = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 1', "#{search}%"])
    short_code_like = sanitize_sql_array(['WHEN short_code ILIKE ? THEN 0.5', "%#{search}%"])
    content_like = sanitize_sql_array(['WHEN content ILIKE ? THEN 0.2', "%#{search}%"])

    order_clause = "CASE #{short_code_starts_with} #{short_code_like} #{content_like} ELSE 0 END"

    order(Arel.sql(order_clause) => :desc)
  }

  private

  # Asynchronously index new canned response to ZeroDB
  def index_async
    return unless zerodb_enabled?

    Zerodb::IndexCannedResponseJob.perform_later(id, account_id)
  end

  # Asynchronously reindex updated canned response to ZeroDB
  def reindex_async
    return unless zerodb_enabled?
    return unless saved_change_to_content? || saved_change_to_short_code?

    Zerodb::IndexCannedResponseJob.perform_later(id, account_id)
  end

  # Asynchronously remove deleted canned response from ZeroDB index
  def remove_from_index_async
    return unless zerodb_enabled?

    Zerodb::DeleteCannedResponseJob.perform_later(id, account_id, short_code)
  end

  # Check if ZeroDB integration is enabled
  def zerodb_enabled?
    ENV['ZERODB_API_KEY'].present? && ENV['ZERODB_PROJECT_ID'].present?
  end
end
