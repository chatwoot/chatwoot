class DataImports::Freshdesk::SourceBucket
  SOURCE_TYPES = {
    1 => 'email',
    2 => 'portal',
    3 => 'phone',
    4 => 'forum',
    5 => 'twitter',
    6 => 'facebook',
    7 => 'chat',
    8 => 'mobihelp',
    9 => 'feedback_widget',
    10 => 'outbound_email',
    11 => 'ecommerce',
    12 => 'bot',
    13 => 'whatsapp',
    14 => 'chat_internal_task'
  }.freeze

  BUCKETS = {
    'email' => { key: 'email', name: 'Email' },
    'outbound_email' => { key: 'email', name: 'Email' },
    'phone' => { key: 'phone', name: 'Phone' },
    'forum' => { key: 'forum', name: 'Forum' },
    'twitter' => { key: 'twitter', name: 'Twitter' },
    'facebook' => { key: 'facebook', name: 'Facebook' },
    'portal' => { key: 'portal', name: 'Portal' },
    'feedback_widget' => { key: 'portal', name: 'Portal' },
    'chat' => { key: 'chat', name: 'Chat' },
    'mobihelp' => { key: 'mobile', name: 'Mobile' },
    'ecommerce' => { key: 'ecommerce', name: 'Ecommerce' },
    'bot' => { key: 'bot', name: 'Bot' },
    'whatsapp' => { key: 'whatsapp', name: 'WhatsApp' },
    'chat_internal_task' => { key: 'internal_task', name: 'Internal task' }
  }.freeze

  DEFAULT_BUCKET = { key: 'unknown', name: 'Unknown' }.freeze

  def self.source_type(value)
    SOURCE_TYPES[value.to_i] || 'unknown'
  end

  def self.for(source_type)
    BUCKETS[source_type.to_s.downcase] || DEFAULT_BUCKET
  end
end
