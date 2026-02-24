json.payload do
  json.array! @contact_pipeline_stages do |cps|
    json.id cps.id
    json.contact_id cps.contact_id
    json.pipeline_stage_id cps.pipeline_stage_id
    json.pipeline_stage_title cps.pipeline_stage.title
    json.pipeline_stage_position cps.pipeline_stage.position
    json.label_id cps.pipeline_stage.label_id
    json.label_title cps.pipeline_stage.label.title
  end
end
