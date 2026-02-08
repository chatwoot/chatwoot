json.payload do
  json.array! @sla_policies do |sla_policy|
    json.partial! 'api/v1/models/sla_policy', formats: [:json], sla_policy: sla_policy
  end
end
