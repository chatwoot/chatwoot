module Enterprise::Audit::Account
  extend ActiveSupport::Concern

  included do
    has_associated_audits
  end
end
