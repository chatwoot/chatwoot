# == Schema Information
#
# Table name: captain_documents
#
#  id            :bigint           not null, primary key
#  chunking_status      :integer          default("pending"), not null
#  chunks_generated_at :datetime
#  content       :text
#  expected_chunk_count :integer          default(0), not null
#  external_link :string           not null
#  indexed_chunk_count :integer          default(0), not null
#  last_chunk_error    :text
#  metadata      :jsonb
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
#  index_captain_documents_on_chunks_generated_at             (chunks_generated_at)
#  index_captain_documents_on_chunking_status                 (chunking_status)
#  index_captain_documents_on_status                          (status)
#
class Captain::Document < ApplicationRecord
  class LimitExceededError < StandardError; end
  self.table_name = 'captain_documents'

  belongs_to :assistant, class_name: 'Captain::Assistant'
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy, as: :documentable
  has_many :chunks, class_name: 'Captain::DocumentChunk', dependent: :destroy
  belongs_to :account
  has_one_attached :pdf_file

  validates :external_link, presence: true, unless: -> { pdf_file.attached? }
  validates :external_link, uniqueness: { scope: :assistant_id }, allow_blank: true
  validates :content, length: { maximum: 200_000 }
  validates :pdf_file, presence: true, if: :pdf_document?
  validate :validate_pdf_format, if: :pdf_document?
  validate :validate_file_attachment, if: -> { pdf_file.attached? }
  before_validation :ensure_account_id
  before_validation :set_external_link_for_pdf
  before_validation :normalize_external_link

  enum status: {
    in_progress: 0,
    available: 1
  }

  enum chunking_status: {
    pending: 0,
    chunking: 1,
    indexing: 2,
    ready: 3,
    failed: 4
  }, _prefix: true

  before_create :ensure_within_plan_limit
  after_create_commit :enqueue_crawl_job
  after_create_commit :update_document_usage
  after_destroy :update_document_usage
  after_commit :enqueue_response_builder_job
  after_commit :enqueue_chunk_builder_job
  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_assistant, ->(assistant_id) { where(assistant_id: assistant_id) }

  def pdf_document?
    return true if pdf_file.attached? && pdf_file.blob.content_type == 'application/pdf'

    external_link&.ends_with?('.pdf')
  end

  def content_type
    pdf_file.blob.content_type if pdf_file.attached?
  end

  def file_size
    pdf_file.blob.byte_size if pdf_file.attached?
  end

  def openai_file_id
    metadata&.dig('openai_file_id')
  end

  def store_openai_file_id(file_id)
    update!(metadata: (metadata || {}).merge('openai_file_id' => file_id))
  end

  def display_url
    return external_link if external_link.present? && !external_link.start_with?('PDF:')

    if pdf_file.attached?
      Rails.application.routes.url_helpers.rails_blob_url(pdf_file, only_path: false)
    else
      external_link
    end
  end

  private

  def enqueue_crawl_job
    return if status != 'in_progress'

    Captain::Documents::CrawlJob.perform_later(self)
  end

  def enqueue_response_builder_job
    return unless should_enqueue_response_builder?

    Captain::Documents::ResponseBuilderJob.perform_later(self)
  end

  def enqueue_chunk_builder_job
    return unless should_enqueue_chunk_builder_job?

    Captain::Documents::ChunkBuilderJob.perform_later(self)
  end

  def should_enqueue_response_builder?
    return false if destroyed?
    return false unless available?
    return false unless document_faq_generation_enabled?

    return saved_change_to_status? if pdf_document?

    (saved_change_to_status? || saved_change_to_content?) && content.present?
  end

  def should_enqueue_chunk_builder_job?
    return false unless chunk_builder_enabled?
    return false if destroyed?
    return false unless available?
    return false if pdf_document?

    (saved_change_to_status? || saved_change_to_content?) && content.present?
  end

  def chunk_builder_enabled?
    value = InstallationConfig.find_by(name: 'CAPTAIN_DOCUMENT_CHUNKING_ENABLED')&.value
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def document_faq_generation_enabled?
    value = assistant&.config&.fetch('feature_document_faq_generation', true)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def update_document_usage
    account.update_document_usage
  end

  def ensure_account_id
    self.account_id = assistant&.account_id
  end

  def ensure_within_plan_limit
    limits = account.usage_limits[:captain][:documents]
    raise LimitExceededError, I18n.t('captain.documents.limit_exceeded') unless limits[:current_available].positive?
  end

  def validate_pdf_format
    return unless pdf_file.attached?

    errors.add(:pdf_file, I18n.t('captain.documents.pdf_format_error')) unless pdf_file.blob.content_type == 'application/pdf'
  end

  def validate_file_attachment
    return unless pdf_file.attached?

    return unless pdf_file.blob.byte_size > 10.megabytes

    errors.add(:pdf_file, I18n.t('captain.documents.pdf_size_error'))
  end

  def set_external_link_for_pdf
    return unless pdf_file.attached? && external_link.blank?

    # Set a unique external_link for PDF files
    # Format: PDF: filename_timestamp (without extension)
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    self.external_link = "PDF: #{pdf_file.filename.base}_#{timestamp}"
  end

  def normalize_external_link
    return if external_link.blank?
    return if pdf_document?

    self.external_link = external_link.delete_suffix('/')
  end
end
