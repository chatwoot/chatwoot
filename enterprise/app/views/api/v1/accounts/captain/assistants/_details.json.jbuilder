json.partial! 'api/v1/models/captain/assistant', formats: [:json], resource: assistant
if pending_follow_up_automations
  json.pending_follow_up_automations pending_follow_up_automations do |automation|
    json.id automation.id
    json.execution_delay automation.execution_delay
  end
end
