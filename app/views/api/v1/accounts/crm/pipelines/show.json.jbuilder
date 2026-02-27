json.extract! @pipeline, :id, :name, :display_order, :created_at, :updated_at
json.stages @pipeline.stages do |stage|
  json.extract! stage, :id, :name, :stage_type, :display_order
end
