module Enterprise::Concerns::Company
  extend ActiveSupport::Concern

  included do
    after_create_commit :enqueue_enrichment, if: -> { domain.present? && Companies::EnrichmentService.enabled_for?(account) }
  end

  private

  def enqueue_enrichment
    Companies::EnrichJob.perform_later(self)
  end
end
