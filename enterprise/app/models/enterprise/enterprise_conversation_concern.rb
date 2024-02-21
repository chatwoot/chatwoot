module Enterprise::EnterpriseConversationConcern
  extend ActiveSupport::Concern

  included do
    belongs_to :sla_policy, optional: true
    has_one :applied_sla, dependent: :destroy
    before_validation :validate_sla_policy, if: -> { sla_policy_id_changed? }
    around_save :around_save_sla_policy
  end

  def validate_sla_policy
    return if sla_policy_id.nil?

    errors.add(:sla_policy, 'sla policy account mismatch') if sla_policy&.account_id != account_id
  end

  private

  def around_save_sla_policy
    ActiveRecord::Base.transaction do
      yield # This saves the conversation, including sla_policy_id changes

      if sla_policy_id.nil?
        applied_sla&.destroy!
      else
        create_or_update_applied_sla
      end
    end
  rescue ActiveRecord::RecordInvalid
    # Handle any exceptions, for example, rollback or add errors
    raise ActiveRecord::Rollback
  end

  def create_or_update_applied_sla
    if applied_sla.nil?
      new_applied_sla = build_applied_sla(sla_policy_id: sla_policy_id)
      new_applied_sla.save!
    else
      applied_sla.update!(sla_policy_id: sla_policy_id)
    end
  end
end
