# Script para criar dados de exemplo de SLA

# Busca ou cria conta, usuário e inbox
account = Account.first || Account.create!(name: 'Demo Account')
user = account.users.first || User.create!(
  email: 'admin@example.com',
  name: 'Admin User',
  password: 'Password123!',
  password_confirmation: 'Password123!'
)
account_user = AccountUser.find_or_create_by!(account: account, user: user) do |au|
  au.role = :administrator
end

inbox = account.inboxes.first
unless inbox
  channel = Channel::WebWidget.create!(account: account, website_url: 'https://example.com')
  inbox = Inbox.create!(
    account: account,
    channel: channel,
    name: 'Website Inbox',
    enable_auto_assignment: true
  )
  InboxMember.create!(inbox: inbox, user: user)
end

contact = account.contacts.first || Contact.create!(
  account: account,
  name: 'Test Customer',
  email: 'customer@example.com'
)

contact_inbox = ContactInbox.find_or_create_by!(
  contact: contact,
  inbox: inbox,
  source_id: SecureRandom.uuid
)

# Criar políticas de SLA
sla1 = SlaPolicy.find_or_create_by!(account: account, name: 'Standard Support') do |s|
  s.first_response_time_threshold = 1.0  # 1 hora
  s.next_response_time_threshold = 2.0   # 2 horas
  s.resolution_time_threshold = 24.0     # 24 horas
  s.description = 'Política padrão para suporte geral'
end

sla2 = SlaPolicy.find_or_create_by!(account: account, name: 'Premium Support') do |s|
  s.first_response_time_threshold = 0.5  # 30 minutos
  s.next_response_time_threshold = 1.0   # 1 hora
  s.resolution_time_threshold = 8.0      # 8 horas
  s.description = 'Política premium com resposta rápida'
end

sla3 = SlaPolicy.find_or_create_by!(account: account, name: 'Critical Issues') do |s|
  s.first_response_time_threshold = 0.25  # 15 minutos
  s.next_response_time_threshold = 0.5    # 30 minutos
  s.resolution_time_threshold = 4.0       # 4 horas
  s.description = 'Para problemas críticos e urgentes'
end

puts "Políticas de SLA criadas: #{SlaPolicy.count}"

# Limpar conversas antigas se existirem
Conversation.where(contact: contact).destroy_all

# Criar conversas com diferentes status de SLA
# 1. Conversa com SLA cumprido
conv1 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :resolved,
  sla_policy_id: sla1.id,
  created_at: 2.days.ago,
  updated_at: 1.day.ago
)

applied_sla1 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla1,
  conversation: conv1
) do |a|
  a.sla_status = :hit
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv1,
  message_type: :incoming,
  content: 'Olá, preciso de ajuda com minha conta',
  sender: contact,
  created_at: 2.days.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv1,
  message_type: :outgoing,
  content: 'Olá! Claro, vou ajudá-lo com isso.',
  sender: user,
  created_at: 2.days.ago + 30.minutes
)

# 2. Conversa com SLA violado
conv2 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open,
  sla_policy_id: sla2.id,
  created_at: 5.hours.ago,
  waiting_since: 5.hours.ago
)

applied_sla2 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla2,
  conversation: conv2
) do |a|
  a.sla_status = :missed
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv2,
  message_type: :incoming,
  content: 'Urgente! Meu sistema está fora do ar!',
  sender: contact,
  created_at: 5.hours.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla2,
  applied_sla: applied_sla2,
  conversation: conv2,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'missed' },
  created_at: 1.hour.ago
)

# 3. Conversa crítica ainda dentro do prazo
conv3 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open,
  sla_policy_id: sla3.id,
  created_at: 10.minutes.ago,
  waiting_since: 10.minutes.ago
)

applied_sla3 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla3,
  conversation: conv3
) do |a|
  a.sla_status = :active
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv3,
  message_type: :incoming,
  content: 'CRÍTICO: Servidor de produção não responde',
  sender: contact,
  created_at: 10.minutes.ago
)

# 4. Conversa resolvida dentro do SLA premium
conv4 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :resolved,
  sla_policy_id: sla2.id,
  created_at: 3.days.ago,
  updated_at: 3.days.ago + 6.hours
)

applied_sla4 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla2,
  conversation: conv4
) do |a|
  a.sla_status = :hit
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv4,
  message_type: :incoming,
  content: 'Como faço para resetar minha senha?',
  sender: contact,
  created_at: 3.days.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv4,
  message_type: :outgoing,
  content: 'Vou te enviar um link para resetar a senha.',
  sender: user,
  created_at: 3.days.ago + 20.minutes
)

SlaEvent.create!(
  account: account,
  sla_policy: sla2,
  applied_sla: applied_sla4,
  conversation: conv4,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'hit' },
  created_at: 3.days.ago + 20.minutes
)

# 5. Conversa com múltiplas violações
conv5 = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :pending,
  sla_policy_id: sla1.id,
  created_at: 30.hours.ago,
  waiting_since: 5.hours.ago
)

applied_sla5 = AppliedSla.find_or_create_by!(
  account: account,
  sla_policy: sla1,
  conversation: conv5
) do |a|
  a.sla_status = :missed
end

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv5,
  message_type: :incoming,
  content: 'Minha fatura está incorreta',
  sender: contact,
  created_at: 30.hours.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv5,
  message_type: :outgoing,
  content: 'Vou verificar sua fatura',
  sender: user,
  created_at: 29.hours.ago
)

Message.create!(
  account: account,
  inbox: inbox,
  conversation: conv5,
  message_type: :incoming,
  content: 'Alguma atualização sobre minha fatura?',
  sender: contact,
  created_at: 5.hours.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla1,
  applied_sla: applied_sla5,
  conversation: conv5,
  inbox: inbox,
  event_type: :frt,
  meta: { status: 'hit' },
  created_at: 29.hours.ago
)

SlaEvent.create!(
  account: account,
  sla_policy: sla1,
  applied_sla: applied_sla5,
  conversation: conv5,
  inbox: inbox,
  event_type: :nrt,
  meta: { status: 'missed' },
  created_at: 2.hours.ago
)

puts "Conversas criadas: #{Conversation.count}"
puts "SLAs aplicados: #{AppliedSla.count}"
puts "Eventos de SLA: #{SlaEvent.count}"
puts ""
puts "Resumo:"
puts "- Conversa 1: SLA Standard - Cumprido (resolvida)"
puts "- Conversa 2: SLA Premium - Violado (aberta há 5h sem resposta)"
puts "- Conversa 3: SLA Critical - Ativo (aberta há 10min, dentro do prazo)"
puts "- Conversa 4: SLA Premium - Cumprido (resolvida em 6h)"
puts "- Conversa 5: SLA Standard - Violado (múltiplas violações)"
puts ""
puts "Login: admin@example.com"
puts "Senha: Password123!"
