json.id @label.id
json.title @label.title
json.description @label.description
json.color @label.color
json.show_on_sidebar @label.show_on_sidebar
json.pipeline_stages @label.pipeline_stages do |stage|
  json.id stage.id
  json.title stage.title
  json.position stage.position
end
