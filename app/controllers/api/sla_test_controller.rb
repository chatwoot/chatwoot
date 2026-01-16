class Api::SlaTestController < ActionController::API
  def create
    account = Account.first
    inbox = account.inboxes.where(channel_type: 'Channel::WebWidget').first

    if inbox.nil?
      return render json: { error: 'Nenhum inbox de widget encontrado' }, status: :not_found
    end

    # Criar ou buscar SLA Policy
    sla_policy = account.sla_policies.first
    unless sla_policy
      sla_policy = account.sla_policies.create!(
        name: 'SLA Exemplo',
        description: 'SLA Policy criada automaticamente para testes',
        first_response_time_threshold: 300,  # 5 minutos
        next_response_time_threshold: 600,   # 10 minutos
        resolution_time_threshold: 3600,     # 1 hora
        only_during_business_hours: false
      )
    end

    # Criar ou buscar contato
    contact = account.contacts.find_or_create_by!(email: params[:email] || "sla-test-#{SecureRandom.hex(4)}@example.com") do |c|
      c.name = params[:name] || 'Cliente Exemplo SLA'
    end

    # Criar ou buscar contact_inbox
    contact_inbox = ContactInbox.find_or_create_by!(
      contact: contact,
      inbox: inbox
    ) do |ci|
      ci.source_id = contact.email
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

    # Criar mensagem
    conversation.messages.create!(
      content: params[:message] || 'Mensagem de teste para visualização de SLA na sidebar',
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

    # Criar eventos de SLA de exemplo
    sla_start_time = applied_sla.created_at.to_i

    # Evento FRT - dentro do prazo
    frt_event_time = sla_start_time + 180 # 3 minutos
    SlaEvent.create!(
      applied_sla: applied_sla,
      conversation: conversation,
      account: account,
      inbox: inbox,
      sla_policy: sla_policy,
      event_type: :frt,
      created_at: Time.at(frt_event_time)
    )

    # Evento NRT - dentro do prazo
    nrt_event_time = sla_start_time + 480 # 8 minutos
    SlaEvent.create!(
      applied_sla: applied_sla,
      conversation: conversation,
      account: account,
      inbox: inbox,
      sla_policy: sla_policy,
      event_type: :nrt,
      created_at: Time.at(nrt_event_time)
    )

    render json: {
      success: true,
      conversation_id: conversation.id,
      conversation_url: "http://localhost:3000/app/accounts/#{account.id}/conversations/#{conversation.id}",
      sla_report_url: "http://localhost:3000/app/accounts/#{account.id}/reports/sla",
      sla_policy_name: sla_policy.name,
      applied_sla_id: applied_sla.id
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
