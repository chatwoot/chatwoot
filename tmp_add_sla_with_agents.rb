# Adicionar conversas com agentes para relatórios SLA

account = Account.first
user = account.users.first
inbox = account.inboxes.first
contact = account.contacts.first
contact_inbox = contact.contact_inboxes.first

# Buscar políticas de SLA
sla1 = SlaPolicy.find_by(account: account, name: 'Standard Support')
sla2 = SlaPolicy.find_by(account: account, name: 'Premium Support')
sla3 = SlaPolicy.find_by(account: account, name: 'Critical Issues')

puts "Criando conversas com agentes atribuídos..."

# 1. Conversa atribuída ao agente - SLA cumprido
conv_with_agent_1 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :resolved,
  sla_policy_id: sla1.id,
  assignee_id: user.id,
  created_at: 1.day.ago,
  updated_at: 1.day.ago + 30.minutes
)

applied_sla_1 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla1,
  conversation: conv_with_agent_1
) do |a|
  a.sla_status = :hit
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_1,
  message_type: :incoming,
  content: 'Preciso de ajuda com uma configuração',
  sender: contact,
  created_at: 1.day.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_1,
  message_type: :outgoing,
  content: 'Claro! Vou te ajudar com isso agora.',
  sender: user,
  created_at: 1.day.ago + 25.minutes
)

SlaEvent.create!(
  account: account,
  sla_policy: sla1,
  applied_sla: applied_sla_1,
  conversation: conv_with_agent_1,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'hit', response_time: 25 },
  created_at: 1.day.ago + 25.minutes
)

puts "✓ Conversa 1 criada: Atribuída a #{user.name}, SLA cumprido"

# 2. Conversa atribuída ao agente - SLA violado
conv_with_agent_2 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open,
  sla_policy_id: sla2.id,
  assignee_id: user.id,
  created_at: 3.hours.ago,
  waiting_since: 3.hours.ago
)

applied_sla_2 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla2,
  conversation: conv_with_agent_2
) do |a|
  a.sla_status = :missed
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_2,
  message_type: :incoming,
  content: 'URGENTE! Sistema de pagamento não está funcionando!',
  sender: contact,
  created_at: 3.hours.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla2,
  applied_sla: applied_sla_2,
  conversation: conv_with_agent_2,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'missed', threshold: 30, actual: 180 },
  created_at: 2.hours.ago
)

puts "✓ Conversa 2 criada: Atribuída a #{user.name}, SLA violado (3h sem resposta)"

# 3. Conversa crítica atribuída - Respondida rapidamente
conv_with_agent_3 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open,
  sla_policy_id: sla3.id,
  assignee_id: user.id,
  created_at: 5.minutes.ago,
  waiting_since: 5.minutes.ago
)

applied_sla_3 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla3,
  conversation: conv_with_agent_3
) do |a|
  a.sla_status = :active
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_3,
  message_type: :incoming,
  content: 'CRÍTICO: Servidor de produção com erro 500',
  sender: contact,
  created_at: 5.minutes.ago
)

puts "✓ Conversa 3 criada: Atribuída a #{user.name}, SLA Crítico ativo"

# 4. Conversa com múltiplas interações - Mix de hit e miss
conv_with_agent_4 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :pending,
  sla_policy_id: sla1.id,
  assignee_id: user.id,
  created_at: 12.hours.ago,
  waiting_since: 1.hour.ago
)

applied_sla_4 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla1,
  conversation: conv_with_agent_4
) do |a|
  a.sla_status = :active_with_misses
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_4,
  message_type: :incoming,
  content: 'Tenho dúvidas sobre a integração com API',
  sender: contact,
  created_at: 12.hours.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_4,
  message_type: :outgoing,
  content: 'Vou verificar a documentação e te retorno',
  sender: user,
  created_at: 11.hours.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv_with_agent_4,
  message_type: :incoming,
  content: 'Conseguiu verificar?',
  sender: contact,
  created_at: 1.hour.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla1,
  applied_sla: applied_sla_4,
  conversation: conv_with_agent_4,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'hit', response_time: 60 },
  created_at: 11.hours.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla1,
  applied_sla: applied_sla_4,
  conversation: conv_with_agent_4,
  inbox: inbox,
  event_type: :nrt,
  meta: { status: 'missed', threshold: 120, actual: 600 },
  created_at: 30.minutes.ago
)

puts "✓ Conversa 4 criada: Atribuída a #{user.name}, FRT cumprido mas NRT violado"

puts ""
puts "=== RESUMO ==="
puts "Total de conversas com SLA: #{Conversation.where.not(sla_policy_id: nil).count}"
puts "Total de Applied SLAs: #{AppliedSla.count}"
puts "Total de SLA Events: #{SlaEvent.count}"
puts ""
puts "Agente: #{user.name} (#{user.email})"
puts "Conversas atribuídas a este agente: #{Conversation.where(assignee_id: user.id).count}"
