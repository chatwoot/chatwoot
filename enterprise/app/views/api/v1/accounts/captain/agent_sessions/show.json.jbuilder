json.id @agent_session.id
json.message_id @agent_session.result_id
json.llm_model @agent_session.llm_model
json.credits_consumed @agent_session.credits_consumed
json.run_context @agent_session.run_context.is_a?(Array) ? @agent_session.run_context : []
json.citations @citations do |citation|
  json.id citation.id
  json.title citation.question
  json.link citation.documentable.is_a?(Captain::Document) ? citation.documentable.external_link : nil
end
json.scenarios @scenario_titles do |id, title|
  json.id id
  json.title title
end
