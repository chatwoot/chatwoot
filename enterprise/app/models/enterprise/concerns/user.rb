module Enterprise::Concerns::User
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_installation_pricing_plan_quantity, on: :create
    after_update_commit :bump_device_trust_version, if: :saved_change_to_device_credentials?

    has_many :captain_responses, class_name: 'Captain::AssistantResponse', dependent: :nullify, as: :documentable
    has_many :copilot_threads, dependent: :destroy_async
  end

  def saved_change_to_device_credentials?
    saved_change_to_encrypted_password? || saved_change_to_email?
  end

  # Atomic increment (not `self.x += 1`) so a concurrent credential change or a
  # "forget trusted devices" call cannot roll the version backward and revive a
  # revoked device cookie.
  def bump_device_trust_version
    self.class.update_counters(id, device_trust_version: 1) # rubocop:disable Rails/SkipsModelValidations
    reset_challenge_budget
  end

  # Recovering credentials clears the challenge budget so other devices are not
  # locked out for the rest of the 24h window. Isolated: this runs after the
  # credential change has committed, so a Redis outage here must not fail the
  # request (in the reset flow that could otherwise leave a reusable reset token).
  def reset_challenge_budget
    DeviceVerification.reset_issuance_budget(id)
  rescue StandardError => e
    Rails.logger.warn "Device verification budget reset failed for user #{id}: #{e.message}"
  end

  def ensure_installation_pricing_plan_quantity
    return unless ChatwootHub.pricing_plan == 'premium'

    errors.add(:base, 'User limit reached. Please purchase more licenses from super admin') if User.count >= ChatwootHub.pricing_plan_quantity
  end
end
