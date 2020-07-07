module Redis::RedisKeys
  ROUND_ROBIN_AGENTS = 'ROUND_ROBIN_AGENTS:%<inbox_id>d'.freeze

  CONVERSATION_MAILER_KEY = 'CONVERSATION::%<conversation_id>d'.freeze

  ## Online Status Keys
  # hash containing user_id key and status as value
  ONLINE_STATUS = 'ONLINE_STATUS::%<account_id>d'.freeze
  # sorted set storing online presense of account contacts
  ONLINE_PRESENCE_CONTACTS = 'ONLINE_PRESENCE::%<account_id>d::CONTACTS'.freeze
  # sorted set storing online presense of account users
  ONLINE_PRESENCE_USERS = 'ONLINE_PRESENCE::%<account_id>d::USERS'.freeze
end
