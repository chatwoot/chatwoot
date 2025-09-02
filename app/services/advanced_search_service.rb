class AdvancedSearchService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Search parameters
  attribute :query, :string
  attribute :search_type, :string
  attribute :page, :integer, default: 1
  attribute :per_page, :integer, default: 20
  
  # Filter parameters
  attribute :channel_types, array: true, default: []
  attribute :inbox_ids, array: true, default: []
  attribute :agent_ids, array: true, default: []
  attribute :team_ids, array: true, default: []
  attribute :tags, array: true, default: []
  attribute :labels, array: true, default: []
  attribute :date_from, :date
  attribute :date_to, :date
  attribute :status, array: true, default: []
  attribute :priority, array: true, default: []
  attribute :message_types, array: true, default: []
  attribute :sender_types, array: true, default: []
  attribute :custom_attributes, :string
  attribute :sentiment, array: true, default: []

  # Advanced filters
  attribute :has_attachments, :boolean
  attribute :unread_only, :boolean
  attribute :assigned_only, :boolean
  attribute :unassigned_only, :boolean
  attribute :sla_status, array: true, default: []
  attribute :contact_segments, array: true, default: []

  # Performance tracking
  attr_accessor :execution_time, :total_count, :current_user, :current_account

  SEARCH_TYPES = %w[all conversations messages contacts].freeze
  PERFORMANCE_THRESHOLD = 300 # milliseconds for p95

  def initialize(current_user:, current_account:, **attributes)
    @current_user = current_user
    @current_account = current_account
    super(attributes)
    validate_search_type
    normalize_arrays
  end

  def perform
    start_time = Time.current
    
    result = case search_type
             when 'conversations'
               { conversations: search_conversations }
             when 'messages'
               { messages: search_messages }
             when 'contacts'
               { contacts: search_contacts }
             else
               {
                 conversations: search_conversations,
                 messages: search_messages,
                 contacts: search_contacts
               }
             end

    @execution_time = ((Time.current - start_time) * 1000).round(2)
    log_performance_metrics
    
    result.merge(
      meta: {
        execution_time: @execution_time,
        total_results: @total_count,
        page: page,
        per_page: per_page,
        filters_applied: active_filters_count
      }
    )
  end

  private

  def accessible_inbox_ids
    @accessible_inbox_ids ||= current_user.assigned_inboxes.pluck(:id)
  end

  def account_user
    @account_user ||= current_account.account_users.find_by(user: current_user)
  end

  def is_admin?
    account_user&.administrator?
  end

  def search_conversations
    scope = build_conversation_scope
    scope = apply_conversation_filters(scope)
    scope = apply_text_search_to_conversations(scope)
    scope = apply_sorting(scope, 'conversations')
    
    @total_count = scope.count
    paginated_scope = scope.page(page).per(per_page)
    
    # Preload associations for performance
    paginated_scope.includes(
      :contact, :inbox, :assignee, :team, :applied_slas, :queue,
      messages: [:sender, :attachments]
    )
  end

  def search_messages
    scope = build_message_scope
    scope = apply_message_filters(scope)
    scope = apply_text_search_to_messages(scope)
    scope = apply_sorting(scope, 'messages')
    
    @total_count = scope.count
    paginated_scope = scope.page(page).per(per_page)
    
    # Preload associations
    paginated_scope.includes(
      :conversation, :sender, :attachments,
      conversation: [:contact, :inbox, :assignee]
    )
  end

  def search_contacts
    scope = build_contact_scope
    scope = apply_contact_filters(scope)
    scope = apply_text_search_to_contacts(scope)
    scope = apply_sorting(scope, 'contacts')
    
    @total_count = scope.count
    paginated_scope = scope.page(page).per(per_page)
    
    # Preload associations
    paginated_scope.includes(
      :contact_inboxes, :conversations, :custom_attribute_definitions,
      conversations: [:inbox, :assignee]
    )
  end

  def build_conversation_scope
    scope = current_account.conversations
    
    # Apply inbox filtering based on permissions
    unless is_admin? && inbox_ids.empty?
      allowed_inbox_ids = inbox_ids.present? ? 
        (accessible_inbox_ids & inbox_ids) : accessible_inbox_ids
      scope = scope.where(inbox_id: allowed_inbox_ids)
    end
    
    scope
  end

  def build_message_scope
    scope = current_account.messages
    
    # Apply inbox filtering
    unless is_admin? && inbox_ids.empty?
      allowed_inbox_ids = inbox_ids.present? ? 
        (accessible_inbox_ids & inbox_ids) : accessible_inbox_ids
      scope = scope.where(inbox_id: allowed_inbox_ids)
    end
    
    # Limit to last 6 months for performance unless admin with specific date range
    unless is_admin? && (date_from.present? || date_to.present?)
      scope = scope.where('created_at >= ?', 6.months.ago)
    end
    
    scope
  end

  def build_contact_scope
    current_account.contacts.resolved_contacts(
      use_crm_v2: current_account.feature_enabled?('crm_v2')
    )
  end

  def apply_conversation_filters(scope)
    # Channel type filter
    if channel_types.any?
      scope = scope.joins(:inbox).where(inboxes: { channel_type: channel_types })
    end

    # Agent/assignee filter
    if agent_ids.any?
      scope = scope.where(assignee_id: agent_ids)
    elsif assigned_only
      scope = scope.where.not(assignee_id: nil)
    elsif unassigned_only
      scope = scope.where(assignee_id: nil)
    end

    # Team filter
    if team_ids.any?
      scope = scope.where(team_id: team_ids)
    end

    # Status filter
    if status.any?
      scope = scope.where(status: status)
    end

    # Priority filter
    if priority.any?
      scope = scope.where(priority: priority)
    end

    # Date range filter
    scope = apply_date_filter(scope)

    # Labels filter
    if labels.any?
      label_query = labels.map { |label| "%#{label}%" }.join('|')
      scope = scope.where('cached_label_list ~ ?', label_query)
    end

    # Custom attributes filter
    if custom_attributes.present?
      begin
        custom_attrs = JSON.parse(custom_attributes)
        custom_attrs.each do |key, value|
          scope = scope.where("custom_attributes ->> ? ILIKE ?", key, "%#{value}%")
        end
      rescue JSON::ParserError
        # Ignore invalid JSON
      end
    end

    # SLA status filter
    if sla_status.any?
      scope = scope.joins(:applied_slas).where(applied_slas: { sla_status: sla_status })
    end

    # Unread filter
    if unread_only
      scope = scope.where('contact_last_seen_at < last_activity_at OR contact_last_seen_at IS NULL')
    end

    scope
  end

  def apply_message_filters(scope)
    # Message type filter
    if message_types.any?
      scope = scope.where(message_type: message_types)
    end

    # Sender type filter
    if sender_types.any?
      scope = scope.where(sender_type: sender_types)
    end

    # Agent filter (for outgoing messages)
    if agent_ids.any? && sender_types.include?('User')
      scope = scope.where(sender_id: agent_ids, sender_type: 'User')
    end

    # Date range filter
    scope = apply_date_filter(scope)

    # Attachments filter
    if has_attachments
      scope = scope.joins(:attachments).distinct
    end

    # Sentiment filter
    if sentiment.any?
      sentiment_conditions = sentiment.map { |s| "sentiment ->> 'label' = ?" }.join(' OR ')
      scope = scope.where(sentiment_conditions, *sentiment)
    end

    scope
  end

  def apply_contact_filters(scope)
    # Date range filter (based on last activity or creation)
    scope = apply_date_filter(scope)

    # Contact segments filter (if implemented)
    if contact_segments.any?
      # This would require a contact segments system
      # scope = scope.joins(:contact_segments).where(contact_segments: { id: contact_segments })
    end

    scope
  end

  def apply_date_filter(scope)
    if date_from.present?
      scope = scope.where('created_at >= ?', date_from.beginning_of_day)
    end
    
    if date_to.present?
      scope = scope.where('created_at <= ?', date_to.end_of_day)
    end
    
    scope
  end

  def apply_text_search_to_conversations(scope)
    return scope if query.blank?

    # Use different search strategies based on query complexity
    if use_advanced_text_search?
      apply_advanced_conversation_search(scope)
    else
      apply_basic_conversation_search(scope)
    end
  end

  def apply_text_search_to_messages(scope)
    return scope if query.blank?

    if use_advanced_text_search?
      apply_advanced_message_search(scope)
    else
      apply_basic_message_search(scope)
    end
  end

  def apply_text_search_to_contacts(scope)
    return scope if query.blank?

    if use_trigram_search?
      # Use trigram search for better fuzzy matching
      scope.where(
        "(name || ' ' || COALESCE(email, '') || ' ' || COALESCE(phone_number, '') || ' ' || COALESCE(identifier, '')) % ?",
        query
      )
    else
      scope.where(
        "name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR identifier ILIKE :search",
        search: "%#{query}%"
      )
    end
  end

  def apply_advanced_conversation_search(scope)
    # Multi-field search in conversations
    search_conditions = []
    search_params = {}

    # Search in conversation display_id
    if query =~ /\A#?\d+\z/
      display_id = query.gsub('#', '').to_i
      search_conditions << "conversations.display_id = :display_id"
      search_params[:display_id] = display_id
    end

    # Search in contact information
    search_conditions << "contacts.name ILIKE :contact_search"
    search_conditions << "contacts.email ILIKE :contact_search"
    search_conditions << "contacts.phone_number ILIKE :contact_search"
    search_conditions << "contacts.identifier ILIKE :contact_search"
    search_params[:contact_search] = "%#{query}%"

    # Search in conversation messages
    search_conditions << "messages.content ILIKE :message_search"
    search_params[:message_search] = "%#{query}%"

    # Search in labels
    search_conditions << "conversations.cached_label_list ILIKE :label_search"
    search_params[:label_search] = "%#{query}%"

    combined_condition = search_conditions.join(' OR ')

    scope.joins(:contact)
         .joins("LEFT JOIN messages ON messages.conversation_id = conversations.id")
         .where(combined_condition, search_params)
         .distinct
  end

  def apply_basic_conversation_search(scope)
    # Simpler search for basic queries
    scope.joins(:contact)
         .where(
           "cast(conversations.display_id as text) ILIKE :search OR " \
           "contacts.name ILIKE :search OR " \
           "contacts.email ILIKE :search OR " \
           "contacts.phone_number ILIKE :search OR " \
           "contacts.identifier ILIKE :search",
           search: "%#{query}%"
         )
  end

  def apply_advanced_message_search(scope)
    if current_account.feature_enabled?('search_with_gin')
      apply_gin_message_search(scope)
    else
      apply_trigram_message_search(scope)
    end
  end

  def apply_gin_message_search(scope)
    # Use PostgreSQL full-text search with GIN index
    tsquery = sanitize_for_tsquery(query)
    scope.where('content @@ plainto_tsquery(?)', tsquery)
  end

  def apply_trigram_message_search(scope)
    # Use trigram similarity for fuzzy matching
    scope.where('content % ?', query)
         .order(Arel.sql("similarity(content, #{ActiveRecord::Base.connection.quote(query)}) DESC"))
  end

  def apply_basic_message_search(scope)
    scope.where('messages.content ILIKE ?', "%#{query}%")
  end

  def apply_sorting(scope, type)
    case type
    when 'conversations'
      scope.order(created_at: :desc, id: :desc)
    when 'messages'
      scope.order(created_at: :desc, id: :desc)
    when 'contacts'
      if query.present? && use_trigram_search?
        # Sort by similarity when using trigram search
        scope.order(Arel.sql("similarity(name, #{ActiveRecord::Base.connection.quote(query)}) DESC, created_at DESC"))
      else
        scope.order(last_activity_at: :desc, created_at: :desc)
      end
    else
      scope
    end
  end

  def use_advanced_text_search?
    current_account.feature_enabled?('advanced_search') && query.present? && query.length >= 3
  end

  def use_trigram_search?
    current_account.feature_enabled?('trigram_search')
  end

  def sanitize_for_tsquery(query)
    # Remove special characters that could break tsquery
    query.gsub(/[^\w\s]/, ' ').strip.split.join(' & ')
  end

  def validate_search_type
    self.search_type = 'all' unless SEARCH_TYPES.include?(search_type)
  end

  def normalize_arrays
    # Ensure array attributes are always arrays and remove empty strings
    %w[channel_types inbox_ids agent_ids team_ids tags labels status priority 
       message_types sender_types sentiment sla_status contact_segments].each do |attr|
      value = send(attr)
      value = [value] unless value.is_a?(Array)
      value = value.compact.reject(&:blank?).map(&:to_s)
      send("#{attr}=", value)
    end
  end

  def active_filters_count
    filters = [
      channel_types, inbox_ids, agent_ids, team_ids, tags, labels,
      status, priority, message_types, sender_types, sentiment,
      sla_status, contact_segments
    ].count(&:any?)

    filters += [date_from, date_to, custom_attributes].count(&:present?)
    filters += [has_attachments, unread_only, assigned_only, unassigned_only].count { |f| f == true }
    
    filters
  end

  def log_performance_metrics
    if @execution_time > PERFORMANCE_THRESHOLD
      Rails.logger.warn "AdvancedSearch: Slow query detected - #{@execution_time}ms for #{search_type} search"
      Rails.logger.warn "AdvancedSearch: Query: '#{query}', Filters: #{active_filters_count}, Results: #{@total_count}"
    end

    # Log to metrics system if available
    if defined?(Metrics)
      Metrics.histogram('advanced_search.execution_time').observe(@execution_time / 1000.0, 
        labels: { search_type: search_type, filters: active_filters_count })
      Metrics.counter('advanced_search.queries_total').increment(
        labels: { search_type: search_type, account_id: current_account.id })
    end
  end
end