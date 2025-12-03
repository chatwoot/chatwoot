class Captain::Llm::PdfProcessingService < Llm::LegacyBaseOpenAiService
  include Integrations::LlmInstrumentation

  def initialize(document)
    super()
    @document = document
  end

  def process
    return if document.openai_file_id.present?

    file_id = upload_pdf_to_openai
    raise CustomExceptions::PdfUploadError, I18n.t('captain.documents.pdf_upload_failed') if file_id.blank?

    document.store_openai_file_id(file_id)
  end

  private

  attr_reader :document

  def upload_pdf_to_openai
    with_tempfile do |temp_file|
      instrument_file_upload do
        response = @client.files.upload(
          parameters: {
            file: temp_file,
            purpose: 'assistants'
          }
        )
        response['id']
      end
    end
  end

  def instrument_file_upload(&)
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span('llm.file.upload') do |span|
      span.set_attribute('gen_ai.provider', 'openai')
      span.set_attribute('file.purpose', 'assistants')
      span.set_attribute('langfuse.user_id', document.account_id.to_s)
      span.set_attribute('langfuse.tags', ['pdf_upload'].to_json)
      span.set_attribute('langfuse.metadata.document_id', document.id.to_s)

      file_id = yield
      span.set_attribute('file.id', file_id) if file_id
      file_id
    end
  end

  def with_tempfile(&)
    Tempfile.create(['pdf_upload', '.pdf'], binmode: true) do |temp_file|
      temp_file.write(document.pdf_file.download)
      temp_file.close

      File.open(temp_file.path, 'rb', &)
    end
  end
end
