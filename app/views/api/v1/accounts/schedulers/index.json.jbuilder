json.array! @schedulers do |scheduler|
  json.partial! 'api/v1/models/scheduler', formats: [:json], resource: scheduler
end
