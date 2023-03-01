module Enterprise::Audit::Inbox
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account
  end
end
