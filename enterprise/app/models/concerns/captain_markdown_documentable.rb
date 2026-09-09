module Concerns::CaptainMarkdownDocumentable
  extend ActiveSupport::Concern

  MARKDOWN_MAX_LENGTH = 10_000
  MARKDOWN_CONTENT_TYPES = %w[text/markdown text/plain text/x-markdown].freeze

  included do
    attr_accessor :markdown_content

    has_one_attached :markdown_file
    validates :content, presence: true, if: :markdown_document?
    validate :validate_markdown_file, if: -> { markdown_file.attached? }
    before_validation :prepare_markdown_document, if: -> { new_record? && markdown_content.present? }
    before_validation :set_external_link_for_markdown
  end

  def markdown_document?
    markdown_file.attached? || external_link&.start_with?('MARKDOWN:')
  end

  private

  def validate_markdown_file
    valid_markdown_file = MARKDOWN_CONTENT_TYPES.include?(markdown_file.blob.content_type) &&
                          markdown_file.filename.extension_without_delimiter.casecmp?('md')
    errors.add(:markdown_file, I18n.t('captain.documents.markdown_format_error')) unless valid_markdown_file
    errors.add(:markdown_file, I18n.t('captain.documents.markdown_size_error')) if content.to_s.length > MARKDOWN_MAX_LENGTH
  end

  def prepare_markdown_document
    self.name = "#{name.presence || 'playground-knowledge'}.md" unless name.to_s.downcase.end_with?('.md')
    self.content = markdown_content
    self.status = :available
    markdown_file.attach(io: StringIO.new(markdown_content), filename: name, content_type: 'text/markdown', identify: false)
  end

  def set_external_link_for_markdown
    return unless markdown_file.attached? && external_link.blank?

    self.external_link = "MARKDOWN: #{markdown_file.filename.base}_#{SecureRandom.hex(8)}.md"
  end
end
