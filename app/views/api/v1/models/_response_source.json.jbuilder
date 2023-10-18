json.id resource.id
json.name resource.name
json.source_link resource.source_link
json.source_type resource.source_type
json.account_id resource.account_id
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
json.response_documents do
  json.array! resource.response_documents do |response_document|
    json.id response_document.id
    json.document_link response_document.document_link
    json.created_at response_document.created_at.to_i
    json.updated_at response_document.updated_at.to_i
  end
end
