# == Schema Information
#
# Table name: captain_llm_failure_logs
#
#  id               :bigint           not null, primary key
#  endpoint         :string
#  error_class      :string
#  error_code       :integer
#  error_message    :text             not null
#  model            :string
#  provider         :string
#  request_messages :jsonb
#  source           :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint
#  assistant_id     :bigint
#  conversation_id  :bigint
#
# Indexes
#
#  index_captain_llm_failure_logs_on_account_id_and_created_at  (account_id,created_at)
#  index_captain_llm_failure_logs_on_error_code_and_created_at  (error_code,created_at)
#  index_captain_llm_failure_logs_on_source_and_created_at      (source,created_at)
#
class Captain::LlmFailureLog < ApplicationRecord
  self.table_name = 'captain_llm_failure_logs'

  # The pipeline stage that failed. `guard` records early-return config checks
  # (missing key / feature disabled) that never reach the provider.
  SOURCES = %w[chat embedding firecrawl agent legacy guard].freeze

  belongs_to :account, optional: true
  belongs_to :assistant, class_name: 'Captain::Assistant', optional: true
  belongs_to :conversation, class_name: '::Conversation', optional: true

  validates :source, inclusion: { in: SOURCES }
  validates :error_message, presence: true

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
  scope :for_source, ->(source) { where(source: source) }

  def self.prune!(keep_count: 10_000)
    stale_ids = ordered.offset(keep_count).pluck(:id)
    where(id: stale_ids).delete_all
  end
end
