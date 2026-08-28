json.id @agent_session.id
json.message_id @agent_session.result_id
json.llm_model @agent_session.llm_model
json.credits_consumed @agent_session.credits_consumed
json.run_context @agent_session.run_context.is_a?(Array) ? @agent_session.run_context : []
json.citations @citations do |citation|
  json.id citation.id
  json.title citation.name
  # display_url resolves uploaded PDFs to their blob URL; external_link holds a
  # "PDF: ..." placeholder for those. Guard on scheme so placeholders render as
  # plain text instead of dead anchors.
  link = citation.display_url
  json.link link&.match?(%r{\Ahttps?://}) ? link : nil
end
json.used_faqs @used_faqs do |faq|
  json.id faq.id
  json.title faq.question
end
json.scenarios @scenario_titles do |id, title|
  json.id id
  json.title title
end
