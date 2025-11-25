module Enterprise::Audit::ProductCatalog
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account, on: [:create, :update, :destroy]
  end
end
