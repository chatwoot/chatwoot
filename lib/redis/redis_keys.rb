module Redis::RedisKeys
  ## Inbox Keys
  # Array storing the ordered ids for agent round robin assignment
  ROUND_ROBIN_AGENTS = 'ROUND_ROBIN_AGENTS:%<inbox_id>d'.freeze

  ## Conversation keys
  # Detect whether to send an email reply to the conversation
  CONVERSATION_MAILER_KEY = 'CONVERSATION::%<conversation_id>d'.freeze
  # Whether a conversation is muted ?
  CONVERSATION_MUTE_KEY = 'CONVERSATION::%<id>d::MUTED'.freeze

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
  LATEST_CHATWOOT_VERSION = 'LATEST_CHATWOOT_VERSION'.freeze
end
