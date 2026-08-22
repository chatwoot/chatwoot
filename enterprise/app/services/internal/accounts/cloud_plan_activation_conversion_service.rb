# frozen_string_literal: true

class Internal::Accounts::CloudPlanActivationConversionService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'
  PLAN_ACTIVATION_TRACKED_AT = 'cloud_plan_activation_tracked_at'

  pattr_initialize [:account!, :previous_plan_name!, :current_plan_name!, :activated_at!, :conversion_value!, :currency_code!]

  def perform
    return unless ChatwootApp.chatwoot_cloud?

    return unless previous_plan_name == default_plan_name && current_plan_name != default_plan_name
    return if marketing_attribution.blank? || marketing_attribution[PLAN_ACTIVATION_TRACKED_AT].present?
    return if activated_at > account.created_at + 30.days

    enqueue_conversion
    mark_tracked
  end

  private

  def default_plan_name
    @default_plan_name ||= InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG).value.first['name']
  end

  def marketing_attribution
    @marketing_attribution ||= internal_attributes_service.get('marketing_attribution')
  end

  def enqueue_conversion
    Internal::Accounts::MarketingConversionTrackingJob.perform_later(
      account.id,
      'cloud_plan_activation',
      activated_at,
      conversion_value,
      currency_code
    )
  end

  def mark_tracked
    internal_attributes_service.set(
      'marketing_attribution',
      marketing_attribution.merge(PLAN_ACTIVATION_TRACKED_AT => Time.current.iso8601)
    )
  end

  def internal_attributes_service
    @internal_attributes_service ||= Internal::Accounts::InternalAttributesService.new(account)
  end
end
