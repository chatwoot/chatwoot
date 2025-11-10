json.id @product_catalog.id
json.product_id @product_catalog.product_id
json.industry @product_catalog.industry
json.productName @product_catalog.productName
json.type @product_catalog.type
json.subcategory @product_catalog.subcategory
json.listPrice @product_catalog.listPrice
json.description @product_catalog.description
json.payment_options @product_catalog.payment_options
json.link @product_catalog.link
json.pdfLinks @product_catalog.pdfLinks
json.photoLinks @product_catalog.photoLinks
json.videoLinks @product_catalog.videoLinks
json.is_visible @product_catalog.is_visible
json.created_at @product_catalog.created_at
json.updated_at @product_catalog.updated_at

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
