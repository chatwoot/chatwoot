const DEFAULT_CONFIGS = {
  notification_config: {
    channels: [
      {
        channel: 'whatsapp',
        target_chats: ['120363368887496790@g.us'],
      },
    ],
  },
  messaging_config: {
    whatsapp: {
      type: 'whapi',
      enabled: true,
      api_key: 'dummy_api_key',
      channel_id: 'dummy_channel_id',
      tags: {
        developer: 'dummy_tag_id',
        pruebas: 'dummy_tag_id',
        detenido: 'dummy_tag_id',
        uber: 'dummy_tag_id',
        procesar: 'dummy_tag_id',
        soporte: 'dummy_tag_id',
      },
    },
    instagram: {
      type: 'manychat',
      enabled: true,
      page_id: 'dummy_page_id',
      api_key: 'dummy_api_key',
      cookie: 'dummy_cookie',
      csrf_token: 'dummy_csrf_token',
      frontend_bundle: 'dummy_frontend_bundle',
      tags: {
        developer: 'dummy_tag_id',
        pruebas: 'dummy_tag_id',
        detenido: 'dummy_tag_id',
        uber: 'dummy_tag_id',
        procesar: 'dummy_tag_id',
        soporte: 'dummy_tag_id',
      },
    },
  },
  general_store_config: {
    timezone: 'America/Costa_Rica',
    start_business_hour: 6,
    end_business_hour: 19,
  },
  ecommerce_config: {
    type: 'appointment_setting',
    spreadsheet_id: '',
  },
  conversation_config: {
    max_strikes: 3,
    max_follow_ups: 1,
    max_chats_to_load: 30,
    chat_history_limit: 20,
    max_response_retries: 2,
    max_previous_messages: 5,
    min_seconds_ago_for_response: 30,
    last_message_min_hours_ago_follow_up: 1,
  },
  calendly_config: {
    calendly_api_key: 'dummy_api_key',
    calendly_webhook_secret: 'dummy_webhook_secret',
  },
};

export default DEFAULT_CONFIGS;
