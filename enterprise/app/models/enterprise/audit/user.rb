module Enterprise::Audit::User
  extend ActiveSupport::Concern

  included do
    audited only: [:name, :email]
    audited associated_with: :account
  end
end
