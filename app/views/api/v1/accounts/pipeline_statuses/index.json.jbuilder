json.pipeline_statuses do
  json.array! @pipeline_statuses do |pipeline_status|
    json.partial! '/api/v1/models/pipeline_status', pipeline_status: pipeline_status
  end
end
