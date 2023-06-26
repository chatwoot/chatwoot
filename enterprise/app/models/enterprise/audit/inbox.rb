module Enterprise::Audit::Inbox
  extend ActiveSupport::Concern

  included do
    audited on: [:create, :update]
    audited associated_with: :account
  end
end
