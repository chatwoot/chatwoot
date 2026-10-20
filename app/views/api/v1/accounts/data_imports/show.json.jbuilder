json.partial! 'api/v1/accounts/data_imports/data_import', formats: [:json], data_import: @data_import

json.import_errors do
  json.array! @import_errors_finder.import_errors do |import_error|
    json.id import_error.id
    json.error_code import_error.error_code
    json.message import_error.message
    json.source_object_type import_error.source_object_type
    json.source_object_id import_error.source_object_id
    json.details import_error.details
    json.created_at import_error.created_at
  end
end

json.skip_logs do
  json.array! @skip_logs_finder.skip_logs do |skip_log|
    json.id skip_log.id
    json.kind skip_log.details['kind']
    json.error_code skip_log.error_code
    json.message skip_log.message
    json.source_object_type skip_log.source_object_type
    json.source_object_id skip_log.source_object_id
    json.details skip_log.details
    json.created_at skip_log.created_at
  end
end

json.skip_logs_filters do
  json.selected_source_object_type @skip_logs_finder.selected_source_object_type
  json.counts_by_type @skip_logs_finder.counts_by_type
end
