class Captain::Apropos::ResourceFields
  MODELS = {
    'accounts' => 'Account', 'contacts' => 'Contact', 'contact_notes' => 'Note',
    'assistants' => 'Captain::Assistant', 'conversations' => 'Conversation', 'messages' => 'Message',
    'inboxes' => 'Inbox', 'teams' => 'Team', 'labels' => 'Label', 'agents' => 'User',
    'articles' => 'Article', 'faqs' => 'Captain::AssistantResponse'
  }.freeze
  SCALAR_TYPES = %i[integer float decimal string text boolean datetime date].freeze
  SENSITIVE_NAME = /password|token|secret|otp|encrypted|credential/i
  EXCLUDED = {
    'accounts' => %w[feature_flags feature_flags_ext_1],
    'conversations' => %w[uuid cached_label_list],
    'agents' => %w[provider uid sign_in_count current_sign_in_at last_sign_in_at current_sign_in_ip last_sign_in_ip
                   confirmed_at confirmation_sent_at unconfirmed_email remember_created_at type],
    'articles' => %w[draft_title draft_content]
  }.freeze
  JSON_FIELDS = {
    'contacts' => %w[custom_attributes additional_attributes],
    'assistants' => %w[config response_guidelines guardrails],
    'conversations' => %w[custom_attributes],
    'inboxes' => %w[auto_assignment_config csat_config]
  }.freeze

  # Rails supplies structural facts lazily, so catalog loading does not require a
  # database during boot. Exposure remains policy: opaque JSON requires review,
  # authentication fields stay hidden, and published articles never expose drafts.
  # https://api.rubyonrails.org/v7.2/classes/ActiveRecord/ModelSchema/ClassMethods.html#method-i-columns
  def self.for(resource)
    model = MODELS.fetch(resource).constantize
    excluded = EXCLUDED.fetch(resource, []) + Array(model.encrypted_attributes).map(&:to_s)
    model.columns.filter_map do |column|
      next if column.name.match?(SENSITIVE_NAME) || excluded.include?(column.name)
      next unless SCALAR_TYPES.include?(column.type) || JSON_FIELDS.fetch(resource, []).include?(column.name)

      column.name
    end
  end

  def self.metadata(resource, fields)
    model = MODELS.fetch(resource).constantize
    fields.index_with do |field|
      values = model.defined_enums[field]&.keys
      { type: values ? :string : model.type_for_attribute(field).type,
        nullable: model.columns_hash.fetch(field).null, values: values }.compact
    end
  end
end
