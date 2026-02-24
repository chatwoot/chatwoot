json.payload do
  json.array! @pipeline_stages do |stage|
    json.id stage.id
    json.title stage.title
    json.position stage.position
    json.label_id stage.label_id
  end
end
