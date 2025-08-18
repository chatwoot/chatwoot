json.payload do
  json.array! @leaves do |leave|
    json.partial! 'api/v1/models/leave', formats: [:json], leave: leave
  end
end
