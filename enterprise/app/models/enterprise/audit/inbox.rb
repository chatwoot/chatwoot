module Enterprise::Audit::Inbox
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account, on: [:create, :update]
  end
end
