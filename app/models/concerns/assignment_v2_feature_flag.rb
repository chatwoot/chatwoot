# frozen_string_literal: true

module AssignmentV2FeatureFlag
  extend ActiveSupport::Concern

  def assignment_v2_enabled?
    # Check account-level feature flag
    return false unless feature_enabled_for_account?

    # Check for any inbox-level overrides
    return false if inbox_level_override_disabled?

    # Check system-wide killswitch
    !GlobalConfig.get('assignment_v2_disabled', false)
  end

  private

  def feature_enabled_for_account?
    config = GlobalConfig.get('assignment_v2')
    return false unless config&.dig('enabled')

    # If no account allowlist, enable for all
    allowed_accounts = config['accounts']
    return true if allowed_accounts.blank?

    # Check if account is in allowlist
    allowed_accounts.include?(id)
  end

  def inbox_level_override_disabled?
    return false unless respond_to?(:id)

    # Allow per-inbox disabling during migration
    GlobalConfig.get('assignment_v2_disabled_inboxes', []).include?(id)
  end
end
