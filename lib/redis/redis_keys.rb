module Redis::RedisKeys
  ## Inbox Keys
  # Array storing the ordered ids for agent round robin assignment
  ROUND_ROBIN_AGENTS = 'ROUND_ROBIN_AGENTS:%<inbox_id>d'.freeze

  ## Conversation keys
  # Detect whether to send an email reply to the conversation
  CONVERSATION_MAILER_KEY = 'CONVERSATION::%<conversation_id>d'.freeze
  # Whether a conversation is muted ?
  CONVERSATION_MUTE_KEY = 'CONVERSATION::%<id>d::MUTED'.freeze
  CONVERSATION_DRAFT_MESSAGE = 'CONVERSATION::%<id>d::DRAFT_MESSAGE'.freeze

  ## User Keys
  # SSO Auth Tokens
  USER_SSO_AUTH_TOKEN = 'USER_SSO_AUTH_TOKEN::%<user_id>d::%<token>s'.freeze

  ## Online Status Keys
  # hash containing user_id key and status as value
  ONLINE_STATUS = 'ONLINE_STATUS::%<account_id>d'.freeze
  # sorted set storing online presense of account contacts
  ONLINE_PRESENCE_CONTACTS = 'ONLINE_PRESENCE::%<account_id>d::CONTACTS'.freeze
  # sorted set storing online presense of account users
  ONLINE_PRESENCE_USERS = 'ONLINE_PRESENCE::%<account_id>d::USERS'.freeze

  ## Authorization Status Keys
  # Used to track token expiry and such issues for facebook slack integrations etc
  AUTHORIZATION_ERROR_COUNT = 'AUTHORIZATION_ERROR_COUNT:%<obj_type>s:%<obj_id>d'.freeze
  REAUTHORIZATION_REQUIRED =  'REAUTHORIZATION_REQUIRED:%<obj_type>s:%<obj_id>d'.freeze

  ## Internal Installation related keys
  CHATWOOT_INSTALLATION_ONBOARDING = 'CHATWOOT_INSTALLATION_ONBOARDING'.freeze
  CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING = 'CHATWOOT_CONFIG_RESET_WARNING'.freeze
  LATEST_CHATWOOT_VERSION = 'LATEST_CHATWOOT_VERSION'.freeze
  # Check if a message create with same source-id is in progress?
  MESSAGE_SOURCE_KEY = 'MESSAGE_SOURCE_KEY::%<id>s'.freeze
  OPENAI_CONVERSATION_KEY = 'OPEN_AI_CONVERSATION_KEY::V1::%<event_name>s::%<conversation_id>d::%<updated_at>d'.freeze

  ## Sempahores / Locks
  # We don't want to process messages from the same sender concurrently to prevent creating double conversations
  FACEBOOK_MESSAGE_MUTEX = 'FB_MESSAGE_CREATE_LOCK::%<sender_id>s::%<recipient_id>s'.freeze
  IG_MESSAGE_MUTEX = 'IG_MESSAGE_CREATE_LOCK::%<sender_id>s::%<ig_account_id>s'.freeze
  SLACK_MESSAGE_MUTEX = 'SLACK_MESSAGE_LOCK::%<conversation_id>s::%<reference_id>s'.freeze
  EMAIL_MESSAGE_MUTEX = 'EMAIL_CHANNEL_LOCK::%<inbox_id>s'.freeze
end
