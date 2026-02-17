module Enterprise::Audit::KbResource
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account, on: [:create, :update, :destroy]
  end
end
