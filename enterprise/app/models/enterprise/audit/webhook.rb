module Enterprise::Audit::Webhook
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account
  end
end
