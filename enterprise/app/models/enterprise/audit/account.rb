module Enterprise::Audit::Account
  extend ActiveSupport::Concern

  included do
    audited only on: :update
    has_associated_audits
  end
end
