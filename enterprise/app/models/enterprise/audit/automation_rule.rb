module Enterprise::Audit::AutomationRule
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account
  end
end
