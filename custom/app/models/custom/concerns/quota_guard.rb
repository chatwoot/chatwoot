# Model-level quota enforcement: the safety net that covers every create path
# (channel onboarding, OAuth callbacks, platform APIs), not just the primary
# API controllers. See docs/fork/ENTITLEMENTS.md.
module Custom::Concerns::QuotaGuard
  extend ActiveSupport::Concern

  included do
    validate :ensure_quota_capacity, on: :create
  end

  private

  def ensure_quota_capacity
    return if account.blank?
    # Platform-managed infrastructure is exempt: never counted, never blocked
    # by the tenant's plan (docs/fork/adr/0002).
    return if respond_to?(:platform_managed?) && platform_managed?

    resource = Custom::EntitlementService::MODEL_RESOURCES.fetch(self.class.name)
    result = Custom::EntitlementService.new(account).check(resource)
    return if result.allowed?

    errors.add(:base, I18n.t('errors.quota.exceeded',
                             resource: result.resource.to_s.humanize.downcase,
                             current: result.current,
                             limit: result.limit))
  end
end
