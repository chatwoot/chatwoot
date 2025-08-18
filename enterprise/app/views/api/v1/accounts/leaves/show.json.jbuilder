json.payload do
  json.partial! 'api/v1/models/leave', formats: [:json], leave: @leave
end
