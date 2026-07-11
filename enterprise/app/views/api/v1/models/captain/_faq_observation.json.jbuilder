json.id resource.id
json.generated_question resource.generated_question
json.generated_answer resource.generated_answer
json.language resource.language
json.status resource.status
json.created_at resource.created_at.to_i
json.conversation do
  json.id resource.conversation.id
  json.display_id resource.conversation.display_id
end
