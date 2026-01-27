class Captain::Llm::PdfProcessingService
  def initialize(document)
    @document = document
  end

  def process
    validate_pdf_presence!
    true
  end

  private

  attr_reader :document

  def validate_pdf_presence!
    return if document&.pdf_file&.attached?

    raise CustomExceptions::Pdf::ValidationError, I18n.t('captain.documents.pdf_file_missing')
  end
end
