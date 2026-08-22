json.captain_assistant do
  if @captain_assistant.present?
    json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: @captain_assistant
  end
end
