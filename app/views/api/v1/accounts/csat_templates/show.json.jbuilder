json.csat_template do
  json.partial! 'api/v1/models/csat_template', formats: [:json], resource: @template
  index = 0
  json.questions do
    json.array! @template.csat_template_questions do |question|
      json.id question.id
      json.content question.content
      json.label "Question #{index += 1}"
    end
  end
  json.selected_inboxes do
    json.array! @template.inboxes do |inbox|
      json.id inbox.id
      json.name inbox.name
    end
  end
end
