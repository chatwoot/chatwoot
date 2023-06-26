module Enterprise::Audit::User
  extend ActiveSupport::Concern

  included do
    # required only for sign_in and sign_out events, which we are logging manually
    audited only: [
      :availability,
      :display_name,
      :email,
      :name
    ], unless: proc { |_u| true }
  end
end
