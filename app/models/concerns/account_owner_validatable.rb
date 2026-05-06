module AccountOwnerValidatable
  extend ActiveSupport::Concern

  included do
    validate :account_owner_must_belong_to_account
  end

  private

  def account_owner_must_belong_to_account
    return if account_owner_id.blank? || account.blank?
    return if account.users.exists?(id: account_owner_id)

    errors.add(:account_owner_id, "must belong to the same account as the #{self.class.model_name.singular}")
  end
end
