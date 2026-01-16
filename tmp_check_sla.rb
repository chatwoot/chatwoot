puts 'Total Conversations: ' + Conversation.count.to_s
puts 'With SLA Policy: ' + Conversation.where.not(sla_policy_id: nil).count.to_s
puts 'Applied SLAs: ' + AppliedSla.count.to_s
puts ''

Conversation.where.not(sla_policy_id: nil).limit(5).each do |c|
  puts "Conv #{c.id}: Policy=#{c.sla_policy_id}, Status=#{c.status}"
  applied = AppliedSla.find_by(conversation_id: c.id)
  if applied
    puts "  Applied SLA: #{applied.id} - Status: #{applied.sla_status}"
  else
    puts "  No Applied SLA found"
  end
end
