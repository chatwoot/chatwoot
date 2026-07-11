json.array! @task_templates do |task_template|
  json.partial! 'api/v1/models/task_template', resource: task_template
end
