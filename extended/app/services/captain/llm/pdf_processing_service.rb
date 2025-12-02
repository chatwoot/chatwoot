require 'openai'

class Captain::Llm::PdfProcessingService
  def initialize(document)
    @document = document
    @client = OpenAI::Client.new(access_token: ENV.fetch('OPENAI_API_KEY', nil), log_errors: Rails.env.development?)
  end

  def process
    return if @document.openai_file_id.present?

    file_id = upload_file
    raise 'PDF Upload Failed' if file_id.blank?

    @document.store_openai_file_id(file_id)
  rescue StandardError => e
    Rails.logger.error("PdfProcessingService Error: #{e.message}")
    raise e
  end

  private

  def upload_file
    download_and_upload do |file|
      response = @client.files.upload(
        parameters: {
          file: file,
          purpose: 'assistants'
        }
      )
      response['id']
    end
  end

  def download_and_upload
    Tempfile.create(['captain_pdf', '.pdf'], binmode: true) do |temp|
      temp.write(@document.pdf_file.download)
      temp.rewind
      yield temp
    end
  end
end
