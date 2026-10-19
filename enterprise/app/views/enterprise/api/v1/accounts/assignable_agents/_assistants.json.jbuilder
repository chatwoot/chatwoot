Array(@captain_assistants).each do |assistant|
  json.child! do
    json.partial! 'api/v1/models/captain/assistant_slim', formats: [:json], resource: assistant
    json.assignee_type 'Captain::Assistant'
    json.icon 'i-lucide-bot'
    json.availability_status 'offline'
  end
end
