json.associatedApplications do
  json.array! [@identity_json] do |identity_id|
    json.applicationId identity_id
  end
end
