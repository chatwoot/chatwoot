class KbResourceProductCatalog < ApplicationRecord
  belongs_to :kb_resource
  belongs_to :product_catalog

  validates :kb_resource_id, uniqueness: { scope: :product_catalog_id }
end
