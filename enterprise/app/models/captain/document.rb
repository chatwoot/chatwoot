# == Schema Information
#
# Table name: captain_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  external_link :string           not null
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
  validate :validate_file_attachment, if: -> { pdf_file.attached? }
  before_validation :ensure_account_id
  before_validation :set_external_link_for_pdf
  before_validation :normalize_external_link

  enum status: {
    in_progress: 0,
    available: 1
  }

  # Stored under metadata["faq_generation"]["status"] for dashboard progress UI.
  FAQ_GENERATION_STATUS_QUEUED = 'queued'.freeze
  FAQ_GENERATION_STATUS_PROCESSING = 'processing'.freeze
  FAQ_GENERATION_STATUS_COMPLETED = 'completed'.freeze
  FAQ_GENERATION_STATUS_FAILED = 'failed'.freeze

  before_create :ensure_within_plan_limit
  after_create_commit :enqueue_crawl_job
  after_create_commit :update_document_usage
  after_destroy :update_document_usage
  after_commit :enqueue_response_builder_job
  after_commit :broadcast_captain_document_after_update, on: :update
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

  # Payload for ActionCable (dashboard live document / FAQ status).
  def push_event_data
    {
      id: id,
      assistant_id: assistant_id,
      status: status,
      faq_generation: metadata&.dig('faq_generation'),
      updated_at: updated_at.to_i
    }
  end

  # Merges into metadata["faq_generation"] without callbacks (avoids re-enqueue loops).
  def merge_faq_generation_metadata!(attrs)
    return if destroyed?

    attrs = attrs.stringify_keys
    with_lock do
      new_meta = (metadata || {}).deep_dup
      current = (new_meta['faq_generation'] || {}).stringify_keys
      new_meta['faq_generation'] = current.merge(attrs)
      # Intentionally skip callbacks so FAQ status updates do not re-enqueue ResponseBuilderJob.
      update_columns(metadata: new_meta, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
      reload # sync in-memory state for broadcasts
    end
    broadcast_captain_document_update!
  end

  def broadcast_captain_document_update!
    return if destroyed?

    Rails.configuration.dispatcher.dispatch(
      Events::Types::CAPTAIN_DOCUMENT_UPDATED,
      Time.zone.now,
      captain_document: self
    )
  end

  private

  # merge_faq_generation_metadata! already broadcasts; avoid duplicate / stale payloads.
  def broadcast_captain_document_after_update
    return if destroyed?

    pc = previous_changes
    return unless pc.keys.intersect?(%w[status content metadata name])
    return if faq_enqueue_fired_for_this_commit?

    broadcast_captain_document_update!
  end

  def faq_enqueue_fired_for_this_commit?
    return false unless available?

    pc = previous_changes
    return pc.key?('status') if pdf_document?

    (pc.key?('status') || pc.key?('content')) && content.present?
  end

  def enqueue_crawl_job
    return if status != 'in_progress'

    Captain::Documents::CrawlJob.perform_later(self)
  end

  def enqueue_response_builder_job
    return unless should_enqueue_response_builder?

    merge_faq_generation_metadata!(
      'status' => FAQ_GENERATION_STATUS_QUEUED,
      'updated_at' => Time.current.iso8601
    )
    Captain::Documents::ResponseBuilderJob.perform_later(self)
  end

  def should_enqueue_response_builder?
    return false if destroyed?
    return false unless available?

    return saved_change_to_status? if pdf_document?

    (saved_change_to_status? || saved_change_to_content?) && content.present?
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
