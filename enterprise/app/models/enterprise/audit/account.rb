module Enterprise::Audit::Account
  extend ActiveSupport::Concern

  included do
    audited
    has_associated_audits
  end
end
