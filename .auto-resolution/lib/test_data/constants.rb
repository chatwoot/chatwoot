module TestData::Constants
  NUM_ACCOUNTS = 20
  MIN_MESSAGES = 1_000_000  # 1M
  MAX_MESSAGES = 10_000_000 # 10M
  BATCH_SIZE   = 5_000

  MAX_CONVERSATIONS_PER_CONTACT = 20
  INBOXES_PER_ACCOUNT           = 5
  STATUSES                      = %w[open resolved pending].freeze
  MESSAGE_TYPES                 = %w[incoming outgoing].freeze

  MIN_MESSAGES_PER_CONVO = 5
  MAX_MESSAGES_PER_CONVO = 50

  COMPANY_TYPES      = %w[Retail Healthcare Finance Education Manufacturing].freeze
  DOMAIN_EXTENSIONS  = %w[com io tech ai].freeze
  COUNTRY_CODES      = %w[1 44 91 61 81 86 49 33 34 39].freeze # US, UK, India, Australia, Japan, China, Germany, France, Spain, Italy
end
