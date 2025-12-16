module Enterprise::Audit::ProductMedium
  extend ActiveSupport::Concern

  included do
    audited associated_with: :product_catalog, on: [:create, :update, :destroy]
  end
end
