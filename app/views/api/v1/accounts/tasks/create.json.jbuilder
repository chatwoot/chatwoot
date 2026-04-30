json.id @task.id
json.title @task.title
json.description @task.description
json.status @task.status
json.execution_config @task.execution_config
json.entity_type @task.entity_type
json.entity_id @task.entity_id
json.creator_id @task.creator_id
json.created_at @task.created_at
json.updated_at @task.updated_at

if @task.creator.present?
  json.creator do
    json.id @task.creator.id
    json.name @task.creator.name
    json.avatar_url @task.creator.avatar_url
  end
else
  json.creator nil
end
