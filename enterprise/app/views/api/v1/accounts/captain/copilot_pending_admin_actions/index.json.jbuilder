json.array! @pending_actions do |pending_action|
  json.partial! 'api/v1/models/captain/copilot_pending_admin_action', resource: pending_action
end
