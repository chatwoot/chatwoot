json.array! @insights do |insight|
  json.extract! insight, :id, :name, :config, :created_at, :updated_at
  json.user insight.user.name
end
