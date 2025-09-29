class SendCommentReplyJob < ApplicationJob
  queue_as :default

  def perform(contact_inbox_id, conversation)
    Rails.logger.info '=================== SendCommentReplyJob START ==================='

    contact_inbox = ContactInbox.find_by(id: contact_inbox_id)
    unless contact_inbox
      Rails.logger.error "❌ ContactInbox not found for ID: #{contact_inbox_id}"
      return
    end

    account = contact_inbox.inbox.account
    unless account
      Rails.logger.error "❌ Account not found for ContactInbox ID: #{contact_inbox_id}"
      return
    end

    return if conversation.nil?

    comment_id = conversation&.additional_attributes&.[]('comment_id')
    if comment_id.blank?
      Rails.logger.error "❌ Missing comment_id for conversation: #{conversation.id}"
      return
    end

    comment_text = conversation.messages.first&.content || ''

    lang_code = detect_comment_language(comment_text)

    message_content = I18n.t('comment_reply', locale: lang_code)

    job_key = "comment_reply_job_#{conversation.id}"
    if Rails.cache.exist?(job_key)
      Rails.logger.info "⏩ Duplicate job skipped for conversation #{conversation.id}"
      return
    end
    Rails.cache.write(job_key, true, expires_in: 5.seconds)

    if conversation.messages.exists?(message_type: :outgoing, content: message_content)
      Rails.logger.info "⏩ Skipping duplicate reply for conversation #{conversation.id}"
      return
    end

    # Check type of comment (Instagram or Facebook)
    case conversation.additional_attributes['type']
    when 'instagram_comments'
      send_to_instagram_page(contact_inbox, conversation, message_content)
    when 'facebook_comments', 'feed_comments'
      send_to_facebook_page(contact_inbox, conversation, message_content)
    else
      Rails.logger.warn "⚠️ Unsupported comment type: #{conversation.additional_attributes['type']}"
    end
  end

  private

  def detect_comment_language(text)
    spanish_words = /\b(hola|gracias|buenos|dias|tarde|noche|un|muy|nuevo|interesada|interesado|buen|auto|este|se|ve|excelente|grande|producto|servicio|trabajo|buena|genial|soy|eres|gusta|tengo|puedo|necesito|deseo|quiero|informacion|detalles|carro|motor|rueda|puerta|ventana|asiento|volante|freno|precio|costo|venta|comprar|vender|oferta|descuento|credito|seguro|garantia|kilometraje|usado|seminuevo|agencia|sedan|hatchback|suv|coupe|convertible|camioneta|pickup|furgoneta|deportivo|estado|condicion|optimo|impecable|danado|roto|accidentado|gps|bluetooth|camara|sensores|alarma|piel|tela|sunroof|color|rojo|azul|verde|negro|blanco|gris|plateado|amarillo|disponible|stock|reservar|cotizar|cuanto|que|como|donde|cuando|tienen|hay|km|millas|gasolina|diesel|electrico|hibrido|automatica|manual|4x4|traccion|bonito|elegante|estilo|fascina|poderoso|encanta|perfecto|tremendo|pregunta|mensaje|coche|comentario|fenomenal|magnifico|espectacular|fantastico|impresionante|increible|fabrico|probar|conducir|manejar|velocidad|potencia|consumo|rendimiento|seguridad|confort|lujo|equipamiento|accesorios|llantas|faros|led|tecnologia|audio|sonido|piloto|crucero|control|clima|asientos|cuero|madera|carbono|pack|line|edicion|especial|limited|modelo|ano|matricula|itv|revision|mantenimiento|taller|mecanico|presupuesto|financiacion|entrada|cuotas|pago|contado|transferencia|documentacion|papeles|multas|deudas|historial|propietario|particular|profesional|empresa|flota|taxi|uber|ocasion|demostracion|catalogo|ficha|tecnica|potencia|par|cilindrada|consumo|emisiones|impuesto|circulacion|comprehensive|terceros|robo|incendio|granizo|vidrios|responsabilidad|civil|asistencia|carretera|grua|averia|cobertura|prima|deducible|franquicia|peritaje|chasis|carroceria|pintura|oxido|chocado|reparado|original|piezas|recambios|desguace|despiece|subasta|remate|liquidacion|saldo|existencias|unidades|oportunidad|promocion|campana|rebaja|blackfriday|cybermonday|navidad|reyes|verano|invierno|temporada|clearance|outlet|adios|buenas|vale|claro|si|no|amigo|amiga|usted|nosotros|vosotros|ellos|ellas|porque|tambien|pero|aunque|entonces|ahora|despues|antes|ayer|hoy|manana|aqui|alla|alli|ese|aquel|mucho|poco|algun|ningun|siempre|nunca|todavia|ya|asi|solo|bien|mal|mas|menos|quien|cual|cuales|cuantos|cuantas|por|para|sobre|favor|ayuda|respuesta|saludos|encantado|placer|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez|veinte|treinta|cien|mil)\b/ix

    spanish_characters = /[áéíóúñü¿¡]/i
    if text.match?(spanish_words) ||text.match?(spanish_characters)
      :es
    else
      :en
    end
  end

  def send_to_facebook_page(contact_inbox, conversation, message_content)
    channel = contact_inbox.inbox.channel
    access_token = channel.page_access_token
    app_secret_proof = calculate_app_secret_proof(GlobalConfigService.load('FB_APP_SECRET', ''), access_token)

    query = { access_token: access_token }
    query[:appsecret_proof] = app_secret_proof if app_secret_proof

    comment_id = conversation.additional_attributes['comment_id']
    url = build_facebook_url(comment_id)

    Rails.logger.info "🌐 Sending Facebook reply → URL: #{url}"

    response = post_to_facebook(url, message_content, query)
    Rails.logger.info "📩 Facebook API response: #{response.inspect}"

    if response['error'].present?
      Rails.logger.error "❌ Facebook API error: #{response['error']}"
      return
    end

    conversation.messages.create!(
      content: message_content,
      account: contact_inbox.inbox.account,
      inbox: contact_inbox.inbox,
      sender: conversation.assignee || contact_inbox.inbox.account.users.first,
      message_type: :outgoing,
      source_id: response['id'] || response['message_id'],
      private: false
    )

    Rails.logger.info "✅ Facebook reply sent successfully for comment_id #{comment_id}"
  end

  def build_facebook_url(comment_id)
    "https://graph.facebook.com/v23.0/#{comment_id}/comments"
  end

  def post_to_facebook(url, message_text, query)
    HTTParty.post(
      url,
      headers: { 'Content-Type' => 'application/json' },
      query: query,
      body: { message: message_text }.to_json
    )
  end

  def calculate_app_secret_proof(app_secret, access_token)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), app_secret, access_token)
  end

  # New method for Instagram reply
  def send_to_instagram_page(contact_inbox, conversation, message_content)
    channel = contact_inbox.inbox.channel
    access_token = channel.access_token

    comment_id = conversation.additional_attributes['comment_id']
    unless comment_id
      Rails.logger.error '❌ Missing comment_id for Instagram comment'
      return
    end

    url = "https://graph.instagram.com/v23.0/#{comment_id}/replies"

    response = HTTParty.post(
      url,
      body: {
        message: message_content,
        access_token: access_token
      }
    )

    Rails.logger.info "📩 Instagram API response: #{response.inspect}"

    if response.code != 200 || response['error'].present?
      Rails.logger.error "❌ Instagram API error: #{response['error'] || response.body}"
      return
    end

    conversation.messages.create!(
      content: message_content,
      account: contact_inbox.inbox.account,
      inbox: contact_inbox.inbox,
      sender: conversation.assignee || contact_inbox.inbox.account.users.first,
      message_type: :outgoing,
      source_id: response['id'] || response['message_id'],
      private: false
    )

    Rails.logger.info "✅ Instagram reply sent successfully for comment_id #{comment_id}"
  end
end
