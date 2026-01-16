puts "=== VERIFICAÇÃO DE DADOS DE SLA ==="
puts ""
puts "Conversas totais: #{Conversation.count}"
puts "Conversas com SLA: #{Conversation.where.not(sla_policy_id: nil).count}"
puts "Applied SLAs: #{AppliedSla.count}"
puts "SLA Events: #{SlaEvent.count}"
puts "SLA Policies: #{SlaPolicy.count}"
puts ""

account = Account.first
if account
  puts "Account: #{account.name} (ID: #{account.id})"
  puts ""
  
  puts "=== POLÍTICAS DE SLA ==="
  SlaPolicy.where(account: account).each do |sla|
    puts "  - #{sla.name}: FRT=#{sla.first_response_time_threshold}h, NRT=#{sla.next_response_time_threshold}h, RT=#{sla.resolution_time_threshold}h"
  end
  puts ""
  
  puts "=== CONVERSAS COM SLA ==="
  Conversation.where(account: account).where.not(sla_policy_id: nil).order(created_at: :desc).each do |conv|
    applied = AppliedSla.find_by(conversation: conv)
    puts "  Conv #{conv.display_id}: Criada em #{conv.created_at.strftime('%d/%m/%Y %H:%M')} - Status: #{conv.status} - SLA Status: #{applied&.sla_status || 'N/A'}"
  end
  puts ""
  
  # Testar o filtro que a API usa
  puts "=== TESTANDO FILTRO DA API (últimos 7 dias) ==="
  range = 7.days.ago.beginning_of_day..Time.current.end_of_day
  puts "Range: #{range.first} até #{range.last}"
  applied_slas = account.applied_slas.filter_by_date_range(range)
  puts "Applied SLAs no range: #{applied_slas.count}"
  applied_slas.each do |as|
    puts "  - Applied SLA #{as.id}: Conversa #{as.conversation.display_id}, criado em #{as.created_at}, status: #{as.sla_status}"
  end
  
  puts ""
  puts "=== TESTANDO FILTRO (últimos 30 dias) ==="
  range = 30.days.ago.beginning_of_day..Time.current.end_of_day
  puts "Range: #{range.first} até #{range.last}"
  applied_slas = account.applied_slas.filter_by_date_range(range)
  puts "Applied SLAs no range: #{applied_slas.count}"
  
  puts ""
  puts "=== TODOS OS APPLIED SLAS (sem filtro de data) ==="
  account.applied_slas.each do |as|
    puts "  - ID #{as.id}: Conversa #{as.conversation.display_id}, criado #{as.created_at.strftime('%d/%m/%Y %H:%M')}, status: #{as.sla_status}"
  end
end
