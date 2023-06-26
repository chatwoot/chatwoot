module Enterprise::Audit::AccountUser
  extend ActiveSupport::Concern

  included do
    audited on: [:create], associated_with: :account
  end
end
