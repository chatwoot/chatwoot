json.id kb_resource.id
json.name kb_resource.name
json.description kb_resource.description
json.folder_path kb_resource.folder_path
json.file_name kb_resource.file_name
json.content_type kb_resource.content_type
json.file_size kb_resource.file_size
json.s3_url kb_resource.presigned_url
json.is_visible kb_resource.is_visible
json.product_catalog_ids kb_resource.product_catalog_ids
json.product_catalogs kb_resource.product_catalogs do |catalog|
  json.id catalog.id
  json.product_id catalog.product_id
  json.productName catalog.productName
  json.type catalog.type
  json.industry catalog.industry
end
json.created_at kb_resource.created_at
json.updated_at kb_resource.updated_at
