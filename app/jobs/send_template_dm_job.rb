class SendTemplateDmJob < ApplicationJob
  queue_as :default

  def perform(contact_inbox_id, conversation, comment_id)
    Rails.logger.info "=================== SendTemplateDmJob START =======comment_id #{comment_id}============"

    contact_inbox = ContactInbox.find_by(id: contact_inbox_id)
    unless contact_inbox
      Rails.logger.error "❌ ContactInbox not found for ID: #{contact_inbox_id}"
      return
    end

    if conversation.nil?
      Rails.logger.error "❌ Conversation is nil"
      return
    end

    account = contact_inbox.inbox.account
    unless account
      Rails.logger.error "❌ Account not found for ContactInbox ID: #{contact_inbox_id}"
      return
    end

    contact = conversation.contact
    inbox = contact_inbox.inbox
    recipient_id = contact.get_source_id(inbox.id) if contact && inbox

    if recipient_id.blank?
      Rails.logger.error "❌ Missing recipient_id for conversation: #{conversation.id}"
      return
    end

    comment_text = conversation.messages.first&.content || ''

    lang_code = detect_comment_language(comment_text)

    template_message = I18n.t('dm_template', locale: lang_code)

    job_key = "template_dm_job_#{contact_inbox.id}_#{contact.id}_#{comment_id}"

    if Rails.cache.exist?(job_key)
      Rails.logger.info "⏩ Duplicate template DM job skipped for contact_inbox #{contact_inbox.id}, contact #{contact.id}, comment #{comment_id}"
      return
    end

    Rails.cache.write(job_key, true, expires_in: 5.minutes)

    case conversation.additional_attributes['type']
    when 'instagram_comments', 'instagram_dm'
      send_instagram_dm(contact_inbox, recipient_id, template_message, comment_id, conversation)
    when 'facebook_comments', 'facebook_dm', 'feed_comments'
      send_facebook_dm(contact_inbox, recipient_id, template_message, comment_id)
    else
      Rails.logger.warn "⚠️ Unsupported type for template DM: #{conversation.additional_attributes['type']}"
    end
  end

  private

  def channel
    channel::FacebookPage.find_by(id: contact_inbox.inbox.channel_id)
  end

  def detect_comment_language(text)
    spanish_words = /\b(hola|gracias|buenos|dias|tarde|noche|un|muy|nuevo|interesada|interesado|buen|auto|este|se|ve|excelente|grande|producto|servicio|trabajo|buena|genial|soy|eres|gusta|tengo|puedo|necesito|deseo|quiero|informacion|detalles|carro|motor|rueda|puerta|ventana|asiento|volante|freno|precio|costo|venta|comprar|vender|oferta|descuento|credito|seguro|garantia|kilometraje|usado|seminuevo|agencia|sedan|hatchback|suv|coupe|convertible|camioneta|pickup|furgoneta|deportivo|estado|condicion|optimo|impecable|danado|roto|accidentado|gps|bluetooth|camara|sensores|alarma|piel|tela|sunroof|color|rojo|azul|verde|negro|blanco|gris|plateado|amarillo|disponible|stock|reservar|cotizar|cuanto|que|como|donde|cuando|tienen|hay|km|millas|gasolina|diesel|electrico|hibrido|automatica|manual|4x4|traccion|bonito|elegante|estilo|fascina|poderoso|encanta|perfecto|tremendo|pregunta|mensaje|coche|comentario|fenomenal|magnifico|espectacular|fantastico|impresionante|increible|fabrico|probar|conducir|manejar|velocidad|potencia|consumo|rendimiento|seguridad|confort|lujo|equipamiento|accesorios|llantas|faros|led|tecnologia|audio|sonido|piloto|crucero|control|clima|asientos|cuero|madera|carbono|pack|line|edicion|especial|limited|modelo|ano|matricula|itv|revision|mantenimiento|taller|mecanico|presupuesto|financiacion|entrada|cuotas|pago|contado|transferencia|documentacion|papeles|multas|deudas|historial|propietario|particular|profesional|empresa|flota|taxi|uber|ocasion|demostracion|catalogo|ficha|tecnica|potencia|par|cilindrada|consumo|emisiones|impuesto|circulacion|comprehensive|terceros|robo|incendio|granizo|vidrios|responsabilidad|civil|asistencia|carretera|grua|averia|cobertura|prima|deducible|franquicia|peritaje|chasis|carroceria|pintura|oxido|chocado|reparado|original|piezas|recambios|desguace|despiece|subasta|remate|liquidacion|saldo|existencias|unidades|oportunidad|promocion|campana|rebaja|blackfriday|cybermonday|navidad|reyes|verano|invierno|temporada|clearance|outlet|adios|buenas|vale|claro|si|no|amigo|amiga|usted|nosotros|vosotros|ellos|ellas|porque|tambien|pero|aunque|entonces|ahora|despues|antes|ayer|hoy|manana|aqui|alla|alli|ese|aquel|mucho|poco|algun|ningun|siempre|nunca|todavia|ya|asi|solo|bien|mal|mas|menos|quien|cual|cuales|cuantos|cuantas|por|para|sobre|favor|ayuda|respuesta|saludos|encantado|placer|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|veinte|treinta|cien|mil)\b/ix

    spanish_characters = /[áéíóúñü¿¡]/i

    if  text.match?(spanish_words) || text.match?(spanish_characters)
      :es
    else
      :en
    end
  end

  def find_existing_template_facebook_dm_conversation(contact_inbox, contact, inbox, account)
    Conversation.joins(contact_inbox: { contact: :account }, inbox: :account)
                .where(
                  "conversations.contact_id = ? AND conversations.inbox_id = ? AND inboxes.account_id = ? AND conversations.additional_attributes->>'type' = ?",
                  contact.id,
                  inbox.id,
                  account.id,
                  'template_dm'
                )
                .last
  end

  def find_existing_template_insta_dm_conversation(contact_inbox, contact, inbox, account)
    Conversation.joins(contact_inbox: { contact: :account }, inbox: :account)
                .where(
                  "conversations.contact_id = ? AND conversations.inbox_id = ? AND inboxes.account_id = ? AND conversations.additional_attributes->>'type' = ?",
                  contact.id,
                  inbox.id,
                  account.id,
                  'instagram_dm'
                )
                .last
  end

  def find_or_create_template_facebook_dm_conversation(contact_inbox, contact, inbox, account)
    template_dm_conversation = find_existing_template_facebook_dm_conversation(contact_inbox, contact, inbox, account)

    if template_dm_conversation.nil?
      Rails.logger.info "No existing conversation found, creating a new one for contact #{contact.id} in inbox #{inbox.id}"
      template_dm_conversation = Conversation.create!(
        contact: contact,
        inbox: inbox,
        account: account,
        contact_inbox: contact_inbox,
        additional_attributes: { 'type' => 'template_dm' }
      )
    else
      Rails.logger.info "Found existing conversation #{template_dm_conversation.id} for contact #{contact.id} in inbox #{inbox.id}"
    end

    template_dm_conversation
  end

  def find_or_create_template_insta_dm_conversation(contact_inbox, contact, inbox, account)
    template_dm_conversation = find_existing_template_insta_dm_conversation(contact_inbox, contact, inbox, account)

    if template_dm_conversation.nil?
      Rails.logger.info "No existing conversation found, creating a new one for contact #{contact.id} in inbox #{inbox.id}"
      template_dm_conversation = Conversation.create!(
        contact: contact,
        inbox: inbox,
        account: account,
        contact_inbox: contact_inbox,
        additional_attributes: { 'type' => 'instagram_dm' }
      )
    else
      Rails.logger.info "Found existing conversation #{template_dm_conversation.id} for contact #{contact.id} in inbox #{inbox.id}"
    end

    template_dm_conversation
  end

  def send_facebook_dm(contact_inbox, recipient_id, template_message, comment_id)
    channel = contact_inbox.inbox.channel
    access_token = channel.page_access_token
    page_id = channel.page_id
    app_secret = ENV.fetch('FB_APP_SECRET', '')
    app_secret_proof = calculate_app_secret_proof(app_secret, access_token)

    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof.present?

    url = "https://graph.facebook.com/v23.0/#{page_id}/messages"

    body = {
      messaging_type: 'RESPONSE',
      recipient: { comment_id: comment_id },
      message: { text: template_message }
    }

    contact = contact_inbox.contact
    inbox = contact_inbox.inbox
    account = inbox.account

    # Check if template DM has already been sent for this conversation
    existing_conversation = find_existing_template_facebook_dm_conversation(contact_inbox, contact, inbox, account)
    if existing_conversation&.additional_attributes&.dig('template_dm_sent')
      Rails.logger.info "⏩ Skipping duplicate template DM - already sent for conversation #{existing_conversation.id}"
      return
    end

    # Send the message first
    response = HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: query,
      body: body.to_json
    )

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Facebook DM Template API error: #{response['error'] || response.body}"
      return
    end

    # Create conversation and message atomically after successful API call
    ActiveRecord::Base.transaction do
      template_dm_conversation = find_or_create_template_facebook_dm_conversation(contact_inbox, contact, inbox, account)

      template_dm_conversation.messages.create!(
        content: template_message,
        account: account,
        inbox: inbox,
        sender: template_dm_conversation.assignee || account.users.first,
        message_type: :outgoing,
        source_id: response['message_id'] || nil,
        private: false,
        additional_attributes: { 'delivery_status' => 'sent' }
      )

      # Mark template DM as sent
      template_dm_conversation.update!(
        additional_attributes: template_dm_conversation.additional_attributes.merge('template_dm_sent' => true)
      )
    end

    Rails.logger.info '✅ Facebook Template DM sent successfully'
  end

  def send_instagram_dm(contact_inbox, recipient_id, template_message, comment_id, conversation)
    channel = contact_inbox.inbox.channel
    access_token = channel.access_token
    page_id = channel.instagram_id

    url = "https://graph.instagram.com/v23.0/#{page_id}/messages"

    body = {
      recipient: { comment_id: comment_id },
      message: { text: template_message }
    }

    contact = contact_inbox.contact
    inbox = contact_inbox.inbox
    account = inbox.account

    # Check if template DM has already been sent for this conversation
    existing_conversation = find_existing_template_insta_dm_conversation(contact_inbox, contact, inbox, account)
    if existing_conversation&.additional_attributes&.dig('instagram_dm_sent')
      Rails.logger.info "⏩ Skipping duplicate template DM - already sent for conversation #{existing_conversation.id}"
      return
    end

    # Send the message first
    response = HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: { access_token: access_token },
      body: body.to_json
    )

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Instagram DM Template API error: #{response['error'] || response.body}"
      return
    end

    # Create conversation and message atomically after successful API call
    ActiveRecord::Base.transaction do
      template_dm_conversation = find_or_create_template_insta_dm_conversation(contact_inbox, contact, inbox, account)

      template_dm_conversation.messages.create!(
        content: template_message,
        account: account,
        inbox: inbox,
        sender: template_dm_conversation.assignee || account.users.first,
        message_type: :outgoing,
        source_id: response['message_id'] || nil,
        private: false,
        additional_attributes: { 'delivery_status' => 'sent' }
      )

      # Mark template DM as sent
      template_dm_conversation.update!(
        additional_attributes: template_dm_conversation.additional_attributes.merge('instagram_dm_sent' => true)
      )
    end

    Rails.logger.info '✅ Instagram Template DM sent successfully'
  end

  def calculate_app_secret_proof(app_secret, access_token)
    return nil if app_secret.blank? || access_token.blank?

    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), app_secret, access_token)
  end
end
