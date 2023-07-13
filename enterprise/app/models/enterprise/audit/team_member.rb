module Enterprise::Audit::InboxMember
  extend ActiveSupport::Concern

  included do
    audited on: [:create, :update], associated_with: :account
  end
end
