class Captain::Documents::PdfProcessingJob < ApplicationJob
  queue_as :low

  def perform(document)
    return unless document.pdf_document?

    Rails.logger.info "Starting PDF processing for document #{document.id}"
    
    begin
      service = Captain::Tools::PdfProcessingService.new(document)
      extracted_content = service.process
      
      Rails.logger.info "Successfully processed PDF document #{document.id}, extracted #{extracted_content.length} characters"
      
    rescue Captain::Tools::PdfProcessingService::PdfProcessingError => e
      Rails.logger.error "PDF processing failed for document #{document.id}: #{e.message}"
      
      # Mark document as failed (you may want to add a 'failed' status to the enum)
      document.update!(status: :in_progress) # Keep as in_progress for potential retry
      
      # Optionally, you could add a retry mechanism or notification
      raise e
      
    rescue StandardError => e
      Rails.logger.error "Unexpected error processing PDF document #{document.id}: #{e.message}"
      document.update!(status: :in_progress)
      raise e
    end
  end
end