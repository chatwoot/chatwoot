json.stages @stages do |stage|
  json.partial! 'api/v1/accounts/synapseos/pipeline_stages/pipeline_stage', pipeline_stage: stage
end

json.leads @leads do |lead|
  json.id lead.id
  json.pipeline_stage_id lead.pipeline_stage_id
  json.status lead.status
  json.source lead.source
  json.conversation_id lead.conversation_id
  # rota do Chatwoot usa display_id; conversation_id é o id interno. Expor o
  # display pro board abrir o chat certo (PipelinePage usa conversation_display_id).
  json.conversation_display_id lead.conversation&.display_id
  json.created_at lead.created_at
  json.updated_at lead.updated_at
  contact = lead.contact || lead.conversation&.contact
  json.contact do
    json.id contact&.id
    json.name contact&.name || 'Sem contato'
    json.email contact&.email
    json.phone_number contact&.phone_number
    json.avatar_url contact&.avatar_url
  end
  last_deal = lead.deals.order(:created_at).last
  if last_deal.present?
    json.deal do
      json.id last_deal.id
      json.status last_deal.status
      json.amount last_deal.amount.to_f
      json.currency last_deal.currency
      json.closed_at last_deal.closed_at
    end
  else
    json.deal nil
  end
end
