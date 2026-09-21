class Copilot::V2::ResourceRegistry
  DEFINITIONS = {
    'conversations' => { fields: %w[id display_id status priority inbox_id contact_id assignee_id team_id created_at updated_at
                                    last_activity_at waiting_since first_reply_created_at custom_attributes],
                         relationships: { 'messages' => %w[messages conversation_id], 'mentions' => %w[mentions conversation_id],
                                          'participants' => %w[participants conversation_id], 'contact' => %w[contacts id contact_id] } },
    'contacts' => { fields: %w[id name email phone_number identifier blocked created_at updated_at custom_attributes],
                    relationships: { 'conversations' => %w[conversations contact_id], 'notes' => %w[notes contact_id] } },
    'messages' => { fields: %w[id conversation_id content message_type content_type private created_at updated_at], relationships: {} },
    'mentions' => { fields: %w[id conversation_id user_id mentioned_at created_at], relationships: {} },
    'participants' => { fields: %w[id conversation_id user_id created_at], relationships: {} },
    'notes' => { fields: %w[id contact_id user_id content created_at updated_at], relationships: {} }
  }.freeze
  PERSONAL_PREDICATES = %w[assigned_to_me mentioned_me assigned_or_mentioned participating unassigned unattended].freeze
  INTEGER_FIELDS = %w[id display_id inbox_id contact_id conversation_id assignee_id team_id user_id].freeze
  BOOLEAN_FIELDS = %w[private blocked].freeze

  def self.fetch(resource)
    DEFINITIONS.fetch(resource) { raise ArgumentError, 'Unsupported resource' }
  end

  def self.filter_catalog(resource, model)
    fields = fetch(resource)[:fields] - %w[content custom_attributes]
    filters = fields.index_with do |field|
      field_type = type(field)
      { 'type' => field_type, 'operators' => %w[integer timestamp].include?(field_type) ? %w[eq in gte lte] : %w[eq in],
        'values' => model.defined_enums[field]&.keys }.compact
    end
    %w[unassigned unattended].each { |name| filters[name] = { 'type' => 'boolean', 'operators' => ['eq'] } } if resource == 'conversations'
    filters
  end

  def self.type(field)
    return 'object' if field == 'custom_attributes'
    return 'integer' if INTEGER_FIELDS.include?(field)
    return 'boolean' if BOOLEAN_FIELDS.include?(field)
    return 'timestamp' if field.end_with?('_at')

    'string'
  end
end
