json.partial! 'api/v1/models/captain/copilot_pending_admin_action', resource: @pending_action
json.copilot_message do
  json.partial! 'api/v1/models/captain/copilot_message', resource: @copilot_message
end
