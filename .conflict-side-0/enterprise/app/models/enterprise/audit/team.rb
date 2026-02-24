module Enterprise::Audit::Team
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account
  end
end
