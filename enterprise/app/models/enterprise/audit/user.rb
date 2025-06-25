module Enterprise::Audit::User
  extend ActiveSupport::Concern

  included do
    audited only: [
      :availability,
      :display_name,
      :email,
      :name
    ]
    audited associated_with: :account
  end
end
