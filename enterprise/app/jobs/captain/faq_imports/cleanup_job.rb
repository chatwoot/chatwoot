class Captain::FaqImports::CleanupJob < ApplicationJob
  queue_as :low

  def perform(faq_import)
    faq_import.with_lock do
      return unless faq_import.preview? && faq_import.created_at <= 24.hours.ago

      faq_import.source_file.purge if faq_import.source_file.attached?
      faq_import.destroy!
    end
  end
end
