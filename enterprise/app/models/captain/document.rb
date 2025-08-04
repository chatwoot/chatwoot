# == Schema Information
#
# Table name: captain_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  external_link :string           not null
#  name          :string
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
#  index_captain_documents_on_status                          (status)
#
class Captain::Document < ApplicationRecord
  class LimitExceededError < StandardError; end
  self.table_name = 'captain_documents'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy, as: :documentable
  belongs_to :account
  has_one_attached :pdf_file

  validates :external_link, presence: true, unless: -> { pdf_file.attached? }
  validates :external_link, uniqueness: { scope: :assistant_id }, allow_blank: true
  validates :content, length: { maximum: 200_000 }
  validates :pdf_file, presence: true, if: :pdf_document?
  validate :validate_pdf_format, if: :pdf_document?
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
  scope :for_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }

  def pdf_document?
    (external_link&.ends_with?('.pdf')) || (pdf_file.attached? && pdf_file.content_type == 'application/pdf')
  end

  def openai_file_id
    metadata = self[:content].is_a?(Hash) ? self[:content] : {}
    metadata['openai_file_id']
  end

  def store_openai_file_id(file_id)
    current_metadata = self[:content].is_a?(Hash) ? self[:content] : {}
    update!(content: current_metadata.merge('openai_file_id' => file_id).to_json)
  end

  private

  def enqueue_crawl_job
    return if status != 'in_progress'

    Captain::Documents::CrawlJob.perform_later(self)
  end

  def enqueue_response_builder_job
    return if status != 'available'

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

  def validate_pdf_format
    return unless pdf_file.attached?

    unless pdf_file.content_type == 'application/pdf'
      errors.add(:pdf_file, 'must be a PDF file')
    end

    if pdf_file.byte_size > 512.megabytes
      errors.add(:pdf_file, 'must be less than 512MB')
    end
  end
end
