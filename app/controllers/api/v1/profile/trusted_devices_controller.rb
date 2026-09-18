class Api::V1::Profile::TrustedDevicesController < Api::BaseController
  # Forgetting trusted devices bumps the trust version, invalidating every
  # device cookie issued so far; each device re-verifies on next sign-in.
  def destroy
    return head :not_found unless ChatwootApp.enterprise? && DeviceVerification.enabled?

    User.update_counters(current_user.id, device_trust_version: 1) # rubocop:disable Rails/SkipsModelValidations
    head :ok
  end
end
