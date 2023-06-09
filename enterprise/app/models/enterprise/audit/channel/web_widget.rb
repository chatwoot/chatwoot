module Enterprise::Audit::Channel::WebWidget
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account
  end
end
