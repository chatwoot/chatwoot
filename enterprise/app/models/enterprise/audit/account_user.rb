module Enterprise::Audit::AccountUser
  extend ActiveSupport::Concern

  included do
    audited only: [
      :availability,
      :role,
      :account_id,
      :inviter_id,
      :user_id
    ], on: [:create, :update], associated_with: :account
  end
end
