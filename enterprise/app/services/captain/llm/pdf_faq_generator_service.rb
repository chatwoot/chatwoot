class Captain::Llm::PdfFaqGeneratorService < Captain::Llm::FaqGeneratorService
  include Captain::Llm::Concerns::PdfResponsesApi

  def initialize(content_or_file_id, is_pdf_file: false, metadata: {})
    @is_pdf_file = is_pdf_file
    @metadata = metadata
    super(content_or_file_id)
  end

  def generate
    return super unless pdf_processing?

    validate_inputs!
    response = process_pdf_with_responses_api
    parse_response(response)
  rescue ArgumentError, OpenAI::Error
    []
  end

  private

  attr_reader :is_pdf_file, :metadata

  def pdf_processing?
    is_pdf_file && metadata[:openai_file_id]
  end

  def validate_inputs!
    return unless is_pdf_file

    raise ArgumentError, 'Missing file_id for PDF processing' if metadata[:openai_file_id].blank?
    raise ArgumentError, 'Invalid metadata format' unless metadata.is_a?(Hash)
  end
end