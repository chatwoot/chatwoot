# == Schema Information
#
# Table name: ai_agent_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  external_link :string           not null
#  name          :string
#  status        :integer          default("in_progress"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  topic_id      :bigint           not null
#
# Indexes
#
#  index_ai_agent_documents_on_account_id               (account_id)
#  index_ai_agent_documents_on_topic_id                 (topic_id)
#  index_ai_agent_documents_on_topic_id_and_external_link  (topic_id,external_link) UNIQUE
#  index_ai_agent_documents_on_status                   (status)
#
class AIAgent::Document < ApplicationRecord
  class LimitExceededError < StandardError; end
  self.table_name = 'ai_agent_documents'

  belongs_to :topic, class_name: 'AIAgent::Topic'
  has_many :responses, class_name: 'AIAgent::TopicResponse', dependent: :destroy, as: :documentable
  belongs_to :account

  validates :external_link, presence: true
  validates :external_link, uniqueness: { scope: :topic_id }
  validates :content, length: { maximum: 200_000 }
  before_validation :ensure_account_id

  enum status: {
    in_progress: 0,
    available: 1
  }

  before_create :ensure_within_plan_limit
  after_create_commit :enqueue_crawl_job
  after_create_commit :update_document_usage
  after_destroy :update_document_usage
  after_commit :enqueue_response_builder_job
  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_topic, ->(topic_id) { where(topic_id: topic_id) }

  private

  def enqueue_crawl_job
    return if status != 'in_progress'

    AIAgent::Documents::CrawlJob.perform_later(self)
  end

  def enqueue_response_builder_job
    return if status != 'available'

    AIAgent::Documents::ResponseBuilderJob.perform_later(self)
  end

  def update_document_usage
    account.update_document_usage
  end

  def ensure_account_id
    self.account_id = topic&.account_id
  end

  def ensure_within_plan_limit
    limits = account.usage_limits[:ai_agent][:documents]
    raise LimitExceededError, 'Document limit exceeded' unless limits[:current_available].positive?
  end
end
