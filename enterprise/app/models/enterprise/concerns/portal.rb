module Enterprise::Concerns::Portal
  extend ActiveSupport::Concern

  included do
    before_save :track_custom_domain_change
    after_commit :enqueue_cloudflare_verification_if_domain_changed, on: [:create, :update]
  end

  def enqueue_cloudflare_verification
    return if custom_domain.blank?
    return unless ChatwootApp.chatwoot_cloud?

    Enterprise::CloudflareVerificationJob.perform_later(id)
  end

  private

  def track_custom_domain_change
    @custom_domain_changed = true if will_save_change_to_custom_domain?
  end

  def enqueue_cloudflare_verification_if_domain_changed
    return unless @custom_domain_changed

    @custom_domain_changed = false
    enqueue_cloudflare_verification
  end
end
