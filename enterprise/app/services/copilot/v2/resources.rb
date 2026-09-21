class Copilot::V2::Resources
  include Captain::Copilot::ConversationAccess
  include Copilot::V2::ResourceFilters
  include Copilot::V2::EvidenceCapture

  # Provisional internal safety bounds, not approved production execution limits.
  MAX_SELECTED = Copilot::V2::Limits::MAX_SELECTED
  MAX_RELATED = Copilot::V2::Limits::MAX_RELATED
  MAX_EVIDENCE_BYTES = Copilot::V2::Limits::MAX_EVIDENCE_BYTES
  MAX_SNAPSHOT_BYTES = Copilot::V2::Limits::MAX_SNAPSHOT_BYTES
  PAGE_SIZE = Copilot::V2::Limits::PAGE_SIZE

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def catalog
    membership!
    ResourceRegistry::DEFINITIONS.filter_map do |resource, definition|
      next if %w[contacts notes].include?(resource) && !contacts_allowed?

      fields = definition[:fields].index_with { |field| ResourceRegistry.type(field) }
      filters = ResourceRegistry.filter_catalog(resource, scope(resource).klass)
      [resource, { 'fields' => fields, 'filters' => filters,
                   'personal_predicates' => resource == 'conversations' ? ResourceRegistry::PERSONAL_PREDICATES : [],
                   'custom_attributes' => custom_attribute_catalog(resource),
                   'relationships' => definition[:relationships].transform_values(&:first),
                   'evidence_window' => 'Omitted: rolling seven days. Full history: explicit epoch since and current until timestamps.' }]
    end.to_h
  end

  # Keep the public typed selection arguments explicit.
  # rubocop:disable Metrics/ParameterLists
  def select(resource:, fields: nil, filters: [], order: 'oldest', limit: nil, personal: nil, mention_window: nil)
    membership!
    fields = checked_fields(resource, fields)
    ordering = checked_order(resource, order)
    raise ArgumentError, 'Limit must be a positive integer' unless limit.nil? || (limit.is_a?(Integer) && limit.positive?)

    snapshot do
      relation = filtered_scope(resource, filters)
      relation = personal_scope(relation, resource, personal, mention_window)
      count = relation.count
      requested_count = limit ? [count, limit].min : count
      records = relation.reorder(ordering).limit([requested_count, MAX_SELECTED].min).to_a
      rows = selection_rows(records, fields)

      { 'reference_type' => 'selection', 'resource' => resource, 'identity_type' => 'database_id', 'selected_ids' => records.map(&:id),
        'rows' => rows, 'captured_at' => Time.current.iso8601(6),
        'scope' => { 'filters' => filters, 'fields' => fields, 'order' => order, 'personal' => personal,
                     'mention_window' => mention_window, 'requested_limit' => limit },
        'selection' => { 'complete' => records.size == requested_count, 'matching_count' => count, 'requested_count' => requested_count,
                         'selected_count' => records.size, 'server_cap' => MAX_SELECTED, 'cap_reached' => records.size < requested_count } }
    end
  end

  # Called before captured data is supplied to a provider, not when an owner reads historical results.
  # rubocop:enable Metrics/ParameterLists

  def authorize_manifest!(manifest, item_ids: nil)
    membership!
    captured_ids = captured_item_ids(manifest)
    ids = item_ids || captured_ids
    raise ArgumentError, 'Unknown captured item' unless (ids - captured_ids).empty?

    available = scope(manifest.fetch('resource')).where(id: ids).pluck(:id)
    raise Pundit::NotAuthorizedError, 'Selected records unavailable' unless available.sort == ids.sort

    return true unless manifest['reference_type'] == 'evidence'

    authorize_related_manifest!(manifest, ids)
  end

  def self.require_message_evidence!(manifest)
    return if manifest['reference_type'] == 'evidence' && manifest['evidence_resource'] == 'messages'

    raise ArgumentError, 'Message evidence reference required; metadata cannot satisfy this operation'
  end

  def scope(resource)
    membership!
    ResourceRegistry.fetch(resource)
    conversations = accessible_conversations(account: @account, user: @user)
    case resource
    when 'conversations' then conversations
    when 'messages' then @account.messages.where(conversation_id: conversations.select(:id))
    when 'mentions' then Mention.where(account_id: @account.id, user_id: @user.id, conversation_id: conversations.select(:id))
    when 'participants' then ConversationParticipant.where(account_id: @account.id, conversation_id: conversations.select(:id))
    when 'contacts', 'notes'
      contact_scope(resource)
    end
  end

  private

  ResourceRegistry = Copilot::V2::ResourceRegistry

  def checked_order(resource, order)
    raise ArgumentError, 'Order must be oldest, newest or oldest_waiting' unless %w[oldest newest oldest_waiting].include?(order)
    raise ArgumentError, 'Waiting order is conversation-only' if order == 'oldest_waiting' && resource != 'conversations'

    direction = order == 'newest' ? :desc : :asc
    order == 'oldest_waiting' ? { waiting_since: :asc, id: :asc } : { created_at: direction, id: direction }
  end

  def selection_rows(records, fields)
    rows = records.map { |record| project(record, fields) }
    raise ArgumentError, 'Selection metadata exceeds internal byte limit; narrow selection' if rows.to_json.bytesize > MAX_SNAPSHOT_BYTES

    rows
  end

  def captured_item_ids(manifest)
    return manifest.fetch('selected_ids') unless manifest['reference_type'] == 'evidence'

    manifest.fetch('items').select { |item| item['state'] == 'captured' }.pluck('id')
  end

  def authorize_related_manifest!(manifest, ids)
    target = manifest.fetch('evidence_resource')
    # Source deletion does not invalidate stored text. Recheck the resource gate and extant related parents.
    scope(target)
    return true unless target == 'conversations'

    related_ids = manifest.fetch('items').select { |item| ids.include?(item['id']) }.flat_map { |item| item.fetch('records').pluck('id') }.uniq
    authorized_ids = scope(target).where(id: related_ids).pluck(:id)
    raise Pundit::NotAuthorizedError, 'Evidence records unavailable' unless authorized_ids.sort == related_ids.sort

    true
  end

  def custom_attribute_catalog(resource)
    return [] unless %w[contacts conversations].include?(resource)

    model = resource == 'contacts' ? 'contact_attribute' : 'conversation_attribute'
    @account.custom_attribute_definitions.where(attribute_model: model).map do |definition|
      { 'field' => "custom_attributes.#{definition.attribute_key}", 'type' => definition.attribute_display_type,
        'operators' => ['eq'], 'values' => definition.attribute_values }
    end
  end

  def membership!
    raise Pundit::NotAuthorizedError, 'Account is inactive' unless @account.reload.active?

    @membership = @account.account_users.find_by(user_id: @user&.id)
    raise Pundit::NotAuthorizedError, 'Account membership required' unless @membership
  end

  def contact_scope(resource)
    raise Pundit::NotAuthorizedError, 'Contact access denied' unless contacts_allowed?

    resource == 'contacts' ? @account.contacts : Note.where(account_id: @account.id, contact_id: @account.contacts.select(:id))
  end

  def contacts_allowed?
    return @membership.custom_role.permissions.include?('contact_manage') if @membership.custom_role

    @membership.administrator? || @membership.agent?
  end

  def checked_fields(resource, fields)
    allowed = ResourceRegistry.fetch(resource)[:fields]
    fields ||= allowed
    raise ArgumentError, 'Use registered fields only' unless fields.is_a?(Array) && fields.any? && fields.all?(String) && (fields - allowed).empty?

    (['id'] + fields).uniq
  end

  def project(record, fields)
    row = record.attributes.slice(*fields).as_json
    return row unless fields.include?('custom_attributes')

    model = record.is_a?(Conversation) ? 'conversation_attribute' : 'contact_attribute'
    definitions = @account.custom_attribute_definitions.where(attribute_model: model)
    row['custom_attributes'] = record.custom_attributes.slice(*definitions.pluck(:attribute_key))
    row
  end

  def validate_selection!(selection)
    ids = selection['selected_ids']
    return if selection['reference_type'] == 'selection' && ids.is_a?(Array) && ids.size <= MAX_SELECTED && ids.all?(Integer) && ids.uniq == ids

    raise ArgumentError, 'Selection reference required'
  end

  def snapshot(&)
    # Test transactions can supply the boundary; runtime capture must own its short transaction.
    return yield if Rails.env.test? && ApplicationRecord.connection.transaction_open?

    ApplicationRecord.transaction(isolation: :repeatable_read, &)
  end
end
