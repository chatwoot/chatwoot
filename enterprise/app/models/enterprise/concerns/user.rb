module Enterprise::Concerns::User
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_installation_pricing_plan_quantity, on: :create
    before_save :bump_device_trust_version,
                if: -> { persisted? && (will_save_change_to_encrypted_password? || will_save_change_to_email?) }

    has_many :captain_responses, class_name: 'Captain::AssistantResponse', dependent: :nullify, as: :documentable
    has_many :copilot_threads, dependent: :destroy_async
  end

  def bump_device_trust_version
    self.device_trust_version += 1
  end

  def ensure_installation_pricing_plan_quantity
    return unless ChatwootHub.pricing_plan == 'premium'

    errors.add(:base, 'User limit reached. Please purchase more licenses from super admin') if User.count >= ChatwootHub.pricing_plan_quantity
  end
end
