module ChatscommerceService::DefaultConfigs
  private

  def default_configs
    {
      'notifications_config' => notifications_config,
      'messaging_config' => messaging_config,
      'general_store_config' => general_store_config,
      'ecommerce_config' => ecommerce_config,
      'conversation_config' => conversation_config,
      'calendly_config' => calendly_config
    }
  end

  def notifications_config
    {
      channels: [
        {
          channel: 'whatsapp',
          target_chats: ['120363368887496790@g.us']
        }
      ]
    }
  end

  def messaging_config
    {
      whatsapp: whatsapp_config,
      instagram: instagram_config
    }
  end

  def whatsapp_config
    {
      type: 'whapi',
      enabled: true,
      api_key: 'dummy_api_key',
      channel_id: 'dummy_channel_id',
      tags: default_tags
    }
  end

  def instagram_config
    {
      type: 'manychat',
      enabled: true,
      page_id: 'dummy_page_id',
      api_key: 'dummy_api_key',
      cookie: 'dummy_cookie',
      csrf_token: 'dummy_csrf_token',
      frontend_bundle: 'dummy_frontend_bundle',
      tags: default_tags
    }
  end

  def default_tags
    {
      developer: 'dummy_tag_id',
      pruebas: 'dummy_tag_id',
      detenido: 'dummy_tag_id',
      uber: 'dummy_tag_id',
      procesar: 'dummy_tag_id',
      soporte: 'dummy_tag_id'
    }
  end

  def general_store_config
    {
      timezone: 'America/Costa_Rica',
      start_business_hour: 6,
      end_business_hour: 19
    }
  end

  def ecommerce_config
    {
      type: 'appointment_setting',
      spreadsheet_id: ''
    }
  end

  def conversation_config
    {
      max_strikes: 3,
      max_follow_ups: 1,
      max_chats_to_load: 30,
      chat_history_limit: 20,
      max_response_retries: 2,
      max_previous_messages: 5,
      min_seconds_ago_for_response: 30,
      last_message_min_hours_ago_follow_up: 1
    }
  end

  def calendly_config
    {
      calendly_api_key: 'dummy_api_key',
      calendly_webhook_secret: 'dummy_webhook_secret'
    }
  end
end

