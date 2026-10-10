module Enterprise::Concerns::AssignmentPolicy
  extend ActiveSupport::Concern

  included do
    enum assignment_order: { round_robin: 0, balanced: 1 } if ChatwootApp.enterprise?
    belongs_to :eligible_custom_role, class_name: 'CustomRole', optional: true
    validate :eligible_role_belongs_to_account
  end

  private

  def eligible_role_belongs_to_account
    return if eligible_custom_role_id.nil? || eligible_custom_role&.account_id == account_id

    errors.add(:eligible_custom_role, 'must belong to the same account')
  end
end
