class DataImports::Intercom::SourceBucket
  BUCKETS = {
    'email' => { key: 'email', name: 'Email' },
    'instagram' => { key: 'instagram', name: 'Instagram' },
    'facebook' => { key: 'facebook', name: 'Facebook' },
    'sms' => { key: 'sms', name: 'SMS' },
    'twitter' => { key: 'twitter', name: 'Twitter' },
    'whatsapp' => { key: 'whatsapp', name: 'WhatsApp' },
    'phone' => { key: 'phone', name: 'Phone' },
    'phone_call' => { key: 'phone', name: 'Phone' },
    'phone_switch' => { key: 'phone', name: 'Phone' },
    'inapp' => { key: 'messenger', name: 'Messenger' },
    'messenger' => { key: 'messenger', name: 'Messenger' },
    'conversation' => { key: 'messenger', name: 'Messenger' },
    'push' => { key: 'messenger', name: 'Messenger' }
  }.freeze

  DEFAULT_BUCKET = { key: 'unknown', name: 'Unknown' }.freeze

  def self.for(source_type)
    BUCKETS[source_type.to_s.downcase] || DEFAULT_BUCKET
  end
end
