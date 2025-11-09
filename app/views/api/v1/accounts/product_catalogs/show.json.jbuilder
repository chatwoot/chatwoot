json.id @product_catalog.id
json.industry @product_catalog.industry
json.product_service @product_catalog.product_service
json.type @product_catalog.type
json.subcategory @product_catalog.subcategory
json.list_price @product_catalog.list_price
json.currency @product_catalog.currency
json.description @product_catalog.description
json.payment_options @product_catalog.payment_options
json.financing_term @product_catalog.financing_term
json.interest_rate @product_catalog.interest_rate
json.attributes @product_catalog.attributes
json.brand @product_catalog.brand
json.model @product_catalog.model
json.year @product_catalog.year
json.is_visible @product_catalog.is_visible
json.metadata @product_catalog.metadata
json.created_at @product_catalog.created_at
json.updated_at @product_catalog.updated_at

json.created_by do
  json.id @product_catalog.created_by&.id
  json.name @product_catalog.created_by&.name
end

json.updated_by do
  json.id @product_catalog.updated_by&.id
  json.name @product_catalog.updated_by&.name
end

json.product_media @product_catalog.product_media.ordered do |media|
  json.id media.id
  json.file_type media.file_type
  json.file_name media.file_name
  json.file_url media.file_url
  json.thumbnail_url media.thumbnail_url
  json.mime_type media.mime_type
  json.file_size media.file_size
  json.is_primary media.is_primary
  json.display_order media.display_order
end
