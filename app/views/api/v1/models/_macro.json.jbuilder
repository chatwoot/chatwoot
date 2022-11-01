json.id macro.id
json.name macro.name
json.visibility macro.visibility

if macro.created_by.present?
  json.created_by do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: macro.created_by
  end
end

if macro.updated_by.present?
  json.updated_by do
    json.partial! 'api/v1/models/agent', formats: [:json], resource: macro.updated_by
  end
end

json.account_id macro.account_id
json.actions macro.actions
json.files macro.file_base_data if macro.files.any?
