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

  # Email distribution for company migration testing
  CONTACTS_WITH_COMPANY_NAME_PCT = 30  # Business email + company_name in JSONB
  CONTACTS_BUSINESS_ONLY_PCT = 40      # Business email, no company_name
  CONTACTS_FREE_EMAIL_PCT = 30         # Free/disposable (will be skipped by migration)

  # Business domains - NOT in EmailProviderInfo, will be PROCESSED by migration
  BUSINESS_DOMAINS = %w[
    acme.com
    techcorp.io
    enterprise.com
    innovate.ai
    bigcompany.com
    startup.io
    consulting.com
    services.tech
    solutions.ai
    globalcorp.com
    widgets.com
    datatech.io
    cloudservices.ai
    software.tech
    marketing.com
    finance.io
    healthcare.ai
    manufacturing.com
    retailsolutions.com
    logistics.tech
  ].freeze

  # Free providers - IN EmailProviderInfo, will be SKIPPED by migration
  FREE_EMAIL_PROVIDERS = %w[
    gmail.com
    googlemail.com
    yahoo.com
    yahoo.co.uk
    hotmail.com
    outlook.com
    live.com
    icloud.com
    me.com
    protonmail.com
    aol.com
    mail.com
  ].freeze

  # Disposable providers - detected by ValidEmail2, will be SKIPPED by migration
  # Note: Only include ones that ValidEmail2 actually detects
  DISPOSABLE_EMAIL_PROVIDERS = %w[
    10minutemail.com
    guerrillamail.com
    mailinator.com
  ].freeze
end
