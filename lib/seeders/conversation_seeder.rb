module Seeders::ConversationSeeder
  def self.create_sample_conversations(account, inbox, user)
    # Crear contactos de ejemplo
    contacts = create_sample_contacts(account, inbox)
    
    # Crear conversaciones con diferentes fechas y estados
    conversations = []
    
    # Conversaciones de hace 30 días
    30.times do |i|
      contact = contacts.sample
      conversation = create_conversation_with_date(
        account: account,
        inbox: inbox,
        contact: contact,
        assignee: [user, nil].sample, # Algunas asignadas, otras no
        status: [:open, :resolved, :pending].sample,
        days_ago: 30 - i
      )
      conversations << conversation
      create_sample_messages(conversation, contact, user)
    end
    
    # Conversaciones de la última semana
    7.times do |i|
      contact = contacts.sample
      conversation = create_conversation_with_date(
        account: account,
        inbox: inbox,
        contact: contact,
        assignee: [user, nil].sample,
        status: [:open, :resolved, :pending].sample,
        days_ago: 7 - i
      )
      conversations << conversation
      create_sample_messages(conversation, contact, user)
    end
    
    # Conversaciones de hoy
    5.times do
      contact = contacts.sample
      conversation = create_conversation_with_date(
        account: account,
        inbox: inbox,
        contact: contact,
        assignee: [user, nil].sample,
        status: [:open, :pending].sample, # Solo abiertas o pendientes para hoy
        days_ago: 0
      )
      conversations << conversation
      create_sample_messages(conversation, contact, user)
    end
    
    puts "✅ Creadas #{conversations.count} conversaciones de ejemplo"
    conversations
  end
  
  private
  
  def self.create_sample_contacts(account, inbox)
    contacts = []
    
    contact_data = [
      { name: 'Ana García', email: 'ana.garcia@example.com', phone: '+1234567890' },
      { name: 'Carlos López', email: 'carlos.lopez@example.com', phone: '+1234567891' },
      { name: 'María Rodríguez', email: 'maria.rodriguez@example.com', phone: '+1234567892' },
      { name: 'José Martínez', email: 'jose.martinez@example.com', phone: '+1234567893' },
      { name: 'Laura Sánchez', email: 'laura.sanchez@example.com', phone: '+1234567894' },
      { name: 'David Pérez', email: 'david.perez@example.com', phone: '+1234567895' },
      { name: 'Carmen Gómez', email: 'carmen.gomez@example.com', phone: '+1234567896' },
      { name: 'Miguel Torres', email: 'miguel.torres@example.com', phone: '+1234567897' }
    ]
    
    contact_data.each do |data|
      contact_inbox = ContactInboxWithContactBuilder.new(
        source_id: SecureRandom.uuid,
        inbox: inbox,
        hmac_verified: true,
        contact_attributes: data
      ).perform
      
      contacts << contact_inbox.contact
    end
    
    contacts
  end
  
  def self.create_conversation_with_date(account:, inbox:, contact:, assignee:, status:, days_ago:)
    created_at = days_ago.days.ago + rand(24).hours + rand(60).minutes
    
    conversation = Conversation.create!(
      account: account,
      inbox: inbox,
      status: status,
      assignee: assignee,
      contact: contact,
      contact_inbox: contact.contact_inboxes.find_by(inbox: inbox),
      additional_attributes: {},
      created_at: created_at,
      updated_at: created_at
    )
    
    # Actualizar timestamps manualmente para que reflejen la fecha deseada
    Conversation.where(id: conversation.id).update_all(
      created_at: created_at,
      updated_at: created_at
    )
    
    conversation.reload
  end
  
  def self.create_sample_messages(conversation, contact, user)
    # Mensaje inicial del contacto
    initial_messages = [
      "Hola, necesito ayuda con mi pedido",
      "Tengo un problema con el producto que compré",
      "¿Podrían ayudarme con una consulta?",
      "Mi cuenta no funciona correctamente",
      "Quiero hacer una devolución",
      "Necesito información sobre sus servicios"
    ]
    
    Message.create!(
      content: initial_messages.sample,
      account: conversation.account,
      inbox: conversation.inbox,
      conversation: conversation,
      sender: contact,
      message_type: :incoming,
      created_at: conversation.created_at + 1.minute,
      updated_at: conversation.created_at + 1.minute
    )
    
    # Respuesta del agente (si está asignada)
    if conversation.assignee.present? && [:resolved, :open].include?(conversation.status.to_sym)
      agent_responses = [
        "Hola, gracias por contactarnos. Te ayudo con tu consulta.",
        "¡Hola! Estoy aquí para ayudarte. ¿Podrías darme más detalles?",
        "Gracias por escribirnos. Voy a revisar tu caso.",
        "Hola, entiendo tu situación. Permíteme verificar la información.",
        "¡Hola! Te ayudo inmediatamente con tu solicitud."
      ]
      
      Message.create!(
        content: agent_responses.sample,
        account: conversation.account,
        inbox: conversation.inbox,
        conversation: conversation,
        sender: user,
        message_type: :outgoing,
        created_at: conversation.created_at + 5.minutes,
        updated_at: conversation.created_at + 5.minutes
      )
    end
    
    # Mensaje adicional ocasional
    if rand(3) == 0 # 33% de probabilidad
      follow_up_messages = [
        "Perfecto, muchas gracias por la ayuda",
        "Entiendo, ¿hay algo más que pueda hacer?",
        "Gracias, eso resuelve mi problema",
        "¿Cuánto tiempo tomará el proceso?",
        "Excelente servicio, gracias"
      ]
      
      Message.create!(
        content: follow_up_messages.sample,
        account: conversation.account,
        inbox: conversation.inbox,
        conversation: conversation,
        sender: contact,
        message_type: :incoming,
        created_at: conversation.created_at + 10.minutes,
        updated_at: conversation.created_at + 10.minutes
      )
    end
  end
end
