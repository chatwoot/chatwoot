namespace :sla do
  desc 'Create test conversation for SLA with guaranteed SLA policy'
  task :create_test, [:name, :email, :message] => :environment do |_t, args|
    name = args[:name] || 'Cliente Exemplo SLA'
    email = args[:email] || "sla-test-#{SecureRandom.hex(4)}@example.com"
    message = args[:message] || 'Mensagem de teste para visualização de SLA na sidebar'

    account = Account.first
    inbox = account.inboxes.where(channel_type: 'Channel::WebWidget').first

    if inbox.nil?
      puts '❌ Nenhum inbox de widget encontrado'
      exit
    end

    # Criar ou buscar SLA Policy
    sla_policy = account.sla_policies.first
    unless sla_policy
      puts '📝 Criando SLA Policy de exemplo...'
      sla_policy = account.sla_policies.create!(
        name: 'SLA Exemplo',
        description: 'SLA Policy criada automaticamente para testes',
        first_response_time_threshold: 300,  # 5 minutos
        next_response_time_threshold: 600,   # 10 minutos
        resolution_time_threshold: 3600,     # 1 hora
        only_during_business_hours: false
      )
      puts "✅ SLA Policy criada: #{sla_policy.name}"
    end

    # Criar contato
    contact = account.contacts.find_or_create_by!(email: email) do |c|
      c.name = name
    end
    contact.update!(name: name) if contact.name != name

    # Criar ou buscar contact_inbox
    contact_inbox = ContactInbox.find_or_create_by!(
      contact: contact,
      inbox: inbox
    ) do |ci|
      ci.source_id = email
    end

    # Criar conversa
    conversation = Conversation.create!(
      account: account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      status: :open,
      sla_policy: sla_policy
    )

    # Criar mensagem inicial
    initial_message = conversation.messages.create!(
      content: message,
      message_type: :incoming,
      account: account,
      inbox: inbox,
      sender: contact
    )

    # Garantir que applied_sla seja criado
    applied_sla = conversation.applied_sla || conversation.create_applied_sla!(
      sla_policy: sla_policy,
      account: account,
      sla_status: :active
    )

    # Criar eventos de SLA para demonstrar diferentes status
    sla_start_time = applied_sla.created_at.to_i

    # Evento FRT - dentro do prazo (verde)
    frt_event_time = sla_start_time + 180 # 3 minutos (dentro de 5 minutos)
    SlaEvent.create!(
      applied_sla: applied_sla,
      conversation: conversation,
      account: account,
      inbox: inbox,
      sla_policy: sla_policy,
      event_type: :frt,
      created_at: Time.at(frt_event_time)
    )

    # Evento NRT - dentro do prazo (verde)
    nrt_event_time = sla_start_time + 480 # 8 minutos (dentro de 10 minutos)
    SlaEvent.create!(
      applied_sla: applied_sla,
      conversation: conversation,
      account: account,
      inbox: inbox,
      sla_policy: sla_policy,
      event_type: :nrt,
      created_at: Time.at(nrt_event_time)
    )

    puts "✅ Conversa ##{conversation.id} criada com SLA aplicado!"
    puts "📧 Contato: #{contact.name} (#{contact.email})"
    puts "🔖 SLA Policy: #{sla_policy.name}"
    puts "📊 Applied SLA ID: #{applied_sla.id}"
    puts "🎯 SLA Events criados: FRT, NRT"
    puts "🔗 Acesse: http://localhost:3000/app/accounts/#{account.id}/conversations/#{conversation.id}"
    puts "📊 SLA Reports: http://localhost:3000/app/accounts/#{account.id}/reports/sla"
  end
end
