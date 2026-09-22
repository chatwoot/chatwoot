class Copilot::V2::ResourceRegistry
  DEFINITIONS = {
    'conversations' => { fields: %w[id display_id status priority inbox_id contact_id assignee_id team_id created_at updated_at
                                    last_activity_at waiting_since first_reply_created_at custom_attributes labels],
                         relationships: { 'messages' => %w[messages conversation_id], 'mentions' => %w[mentions conversation_id],
                                          'participants' => %w[participants conversation_id], 'contact' => %w[contacts id contact_id] } },
    'contacts' => { fields: %w[id name email phone_number identifier blocked created_at updated_at custom_attributes],
                    relationships: { 'conversations' => %w[conversations contact_id], 'notes' => %w[notes contact_id] } },
    'messages' => { fields: %w[id conversation_id content message_type content_type private created_at updated_at], relationships: {} },
    'mentions' => { fields: %w[id conversation_id user_id mentioned_at created_at], relationships: {} },
    'participants' => { fields: %w[id conversation_id user_id created_at], relationships: {} },
    'custom_attribute_definitions' => {
      fields: %w[id attribute_key attribute_display_name attribute_description attribute_display_type attribute_model attribute_values created_at
                 updated_at], relationships: {}
    },
    'notes' => { fields: %w[id contact_id user_id content created_at updated_at], relationships: {} },
    'inboxes' => { fields: %w[id name channel_type portal_id timezone created_at updated_at], relationships: {} },
    'agents' => { fields: %w[id name email created_at updated_at], relationships: {} },
    'teams' => { fields: %w[id name description created_at updated_at], relationships: {} },
    # Deliberately the labels index contract, not the admin-only labels show operation.
    'labels' => { fields: %w[id title description color show_on_sidebar created_at updated_at], relationships: {} },
    'portals' => { fields: %w[id name slug archived custom_domain created_at updated_at],
                   relationships: { 'articles' => %w[articles portal_id] } },
    'articles' => { fields: %w[id title description content status locale portal_id category_id created_at updated_at],
                    relationships: { 'content' => %w[articles id] } },
    'documents' => { fields: %w[id name content external_link status assistant_id last_synced_at created_at updated_at],
                     relationships: { 'content' => %w[documents id], 'faqs' => %w[faqs documentable_id] } },
    'faqs' => { fields: %w[id question answer status assistant_id documentable_id documentable_type created_at updated_at],
                relationships: { 'content' => %w[faqs id] } },
    'notifications' => { fields: %w[id notification_type primary_actor_id primary_actor_type read_at snoozed_until last_activity_at created_at],
                         relationships: { 'conversation' => %w[conversations id primary_actor_id] } },
    'account_settings' => { fields: %w[id name locale created_at updated_at], relationships: {} },
    'inbox_settings' => { fields: %w[id name timezone working_hours_enabled greeting_enabled greeting_message out_of_office_message
                                     enable_auto_assignment allow_messages_after_resolved created_at updated_at],
                          relationships: { 'working_hours' => %w[working_hours inbox_id] } },
    'working_hours' => { fields: %w[id inbox_id day_of_week closed_all_day open_all_day open_hour open_minutes close_hour close_minutes
                                    created_at updated_at],
                         relationships: {} },
    'sla_policies' => { fields: %w[id name description first_response_time_threshold next_response_time_threshold
                                   resolution_time_threshold only_during_business_hours created_at updated_at], relationships: {} },
    'applied_slas' => { fields: %w[id conversation_id sla_policy_id sla_status completed_at created_at updated_at deadlines],
                        relationships: { 'deadlines' => %w[applied_slas id] } },
    'campaigns' => { fields: %w[id display_id title description message inbox_id campaign_type campaign_status created_at updated_at],
                     relationships: {} }

  }.freeze
  PERSONAL_PREDICATES = %w[assigned_to_me mentioned_me assigned_or_mentioned participating unassigned unattended].freeze
  INTEGER_FIELDS = %w[id display_id inbox_id contact_id conversation_id assignee_id team_id user_id day_of_week open_hour open_minutes close_hour
                      close_minutes portal_id category_id assistant_id documentable_id primary_actor_id sla_policy_id first_response_time_threshold
                      next_response_time_threshold resolution_time_threshold].freeze
  BOOLEAN_FIELDS = %w[private blocked closed_all_day open_all_day archived show_on_sidebar working_hours_enabled greeting_enabled
                      enable_auto_assignment allow_messages_after_resolved only_during_business_hours].freeze

  def self.fetch(resource)
    DEFINITIONS.fetch(resource) { raise ArgumentError, "unsupported_capability:#{resource}" }
  end

  def self.filter_catalog(resource, model) # rubocop:disable Metrics/CyclomaticComplexity
    fields = fetch(resource)[:fields] - %w[custom_attributes attribute_values labels deadlines]
    filters = fields.index_with do |field|
      field_type = type(field)
      { 'type' => field_type, 'operators' => %w[integer timestamp].include?(field_type) ? %w[eq in gte lte] : %w[eq in],
        'nullable' => model.columns_hash[field]&.null, 'values' => model.defined_enums[field]&.keys }.compact.tap do |filter|
        filter['operators'] << 'contains' if searchable?(resource, field)
      end
    end
    filters['labels'] = { 'type' => 'string', 'operators' => %w[eq in], 'semantics' => 'Match any provided label' } if resource == 'conversations'
    %w[unassigned unattended].each { |name| filters[name] = { 'type' => 'boolean', 'operators' => ['eq'] } } if resource == 'conversations'
    filters
  end

  def self.searchable?(resource, field)
    %w[name email phone_number identifier title description content question answer
       message].include?(field) && fetch(resource)[:fields].include?(field)
  end

  def self.type(field)
    return 'object' if %w[custom_attributes deadlines].include?(field)
    return 'array' if %w[attribute_values labels].include?(field)
    return 'integer' if INTEGER_FIELDS.include?(field)
    return 'boolean' if BOOLEAN_FIELDS.include?(field)
    return 'timestamp' if field.end_with?('_at')

    'string'
  end
end
