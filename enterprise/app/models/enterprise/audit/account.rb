module Enterprise::Audit::Account
  extend ActiveSupport::Concern

  included do
    audited except: :updated_at, on: [:update]
    has_associated_audits
  end
end
