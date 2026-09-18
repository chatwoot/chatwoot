class Captain::FaqImports::CleanupJob < ApplicationJob
  queue_as :low

  def perform(faq_import)
    faq_import.with_lock do
      if faq_import.preview? && faq_import.created_at <= 24.hours.ago
        faq_import.destroy!
      elsif faq_import.failed? && faq_import.completed_at.present? && faq_import.completed_at <= 24.hours.ago
        faq_import.update!(rows: [])
      end
    end
  end
end
