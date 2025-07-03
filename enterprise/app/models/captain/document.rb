# == Schema Information
#
# Table name: captain_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  content_type  :string
#  document_type :integer          default(0), not null
#  external_link :string           not null
#  file_size     :integer
#  name          :string
#  source_type   :string           default("url")
#  status        :integer          default("in_progress"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  assistant_id  :bigint           not null
#
# Indexes
#
#  index_captain_documents_on_account_id                      (account_id)
#  index_captain_documents_on_assistant_id                    (assistant_id)
#  index_captain_documents_on_assistant_id_and_external_link  (assistant_id,external_link) UNIQUE
#  index_captain_documents_on_content_type                    (content_type)
#  index_captain_documents_on_document_type                   (document_type)
#  index_captain_documents_on_source_type                     (source_type)
#  index_captain_documents_on_status                          (status)
#
class Captain::Document < ApplicationRecord
  class LimitExceededError < StandardError; end
  self.table_name = 'captain_documents'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy, as: :documentable
  belongs_to :account
  has_one_attached :file

  validates :external_link, presence: true
  validates :external_link, uniqueness: { scope: :assistant_id }
  validates :content, length: { maximum: 400_000 }
  validates :source_type, inclusion: { in: %w[url pdf_upload] }, allow_blank: true
  before_validation :ensure_account_id
  before_validation :set_default_source_type

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
  scope :for_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }

  def pdf_document?
    source_type == 'pdf_upload' || file.attached? || pdf_url_format?
  end

  private

  def enqueue_crawl_job
    return if status != 'in_progress'

    Captain::Documents::CrawlJob.perform_later(self)
  end

  def enqueue_response_builder_job
    return if status != 'available'
    # Skip auto-enqueue for PDFs as they handle FAQ generation manually with full content
    return if pdf_document?

    Captain::Documents::ResponseBuilderJob.perform_later(self)
  end

  def update_document_usage
    account.update_document_usage
  end

  def ensure_account_id
    self.account_id = assistant&.account_id
  end

  def ensure_within_plan_limit
    limits = account.usage_limits[:captain][:documents]
    raise LimitExceededError, 'Document limit exceeded' unless limits[:current_available].positive?
  end

  def set_default_source_type
    return if source_type.present?

    self.source_type = if file.attached? || pdf_url_format?
                         'pdf_upload'
                       else
                         'url'
                       end
  end

  def pdf_url_format?
    return false if external_link.blank?

    url = external_link.downcase
    url.end_with?('.pdf') || url.include?('/rails/active_storage/blobs/')
  end
end
