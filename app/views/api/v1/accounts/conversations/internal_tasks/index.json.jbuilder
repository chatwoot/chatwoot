json.array! @internal_tasks do |internal_task|
  json.partial! 'api/v1/models/internal_task', resource: internal_task
end
