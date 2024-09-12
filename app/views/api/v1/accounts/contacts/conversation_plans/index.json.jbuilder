json.payload do
  json.array! @conversation_plans do |conversation_plan|
    json.partial! 'api/v1/conversations/partials/conversation_plan', formats: [:json], resource: conversation_plan
  end
end
