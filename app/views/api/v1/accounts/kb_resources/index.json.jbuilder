json.data do
  json.array! @kb_resources do |resource|
    json.partial! 'api/v1/accounts/kb_resources/kb_resource', kb_resource: resource
  end
end

json.folders @subfolders

json.meta do
  json.current_page @current_page
  json.total_pages @total_pages
  json.total_count @total_count
  json.per_page params[:per_page] || 50
  json.current_folder @current_folder
  json.storage_used @storage_used
  json.storage_limit @storage_limit
end
