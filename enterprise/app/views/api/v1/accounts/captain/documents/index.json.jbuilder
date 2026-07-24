json.payload do
  json.array! @documents do |document|
    json.partial! 'api/v1/models/captain/document', formats: [:json], resource: document
  end
end

json.meta do
  json.total_count @documents_count
  json.page @current_page
  json.sync_interval_hours @sync_interval_hours if @sync_interval_hours.present?
end
