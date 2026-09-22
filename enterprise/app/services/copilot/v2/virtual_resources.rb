# Registered deterministic calculations and existing external reads are not AR scopes.
# External fetches happen outside snapshot transactions and never claim exhaustive coverage.
module Copilot::V2::VirtualResources # rubocop:disable Metrics/ModuleLength
  DEFINITIONS = {
    'reports' => { fields: %w[id metric value scope], inputs: { 'metric' => 'string', 'since' => 'timestamp', 'until' => 'timestamp',
                                                                'dimension' => 'string', 'dimension_id' => 'integer',
                                                                'business_hours' => 'boolean' } },
    'campaign_metrics' => { fields: %w[id audience sent delivered read failed skipped status_counts], inputs: { 'campaign_id' => 'integer' } },
    'linear_issues' => { fields: %w[id identifier title description url createdAt updatedAt state priority], inputs: { 'query' => 'string' } },
    'linear_teams' => { fields: %w[id name key], inputs: {} },
    'linear_team_entities' => { fields: %w[id users projects states labels], inputs: { 'team_id' => 'string' } },
    'linear_linked_issues' => { fields: %w[id title issue], inputs: { 'conversation_id' => 'integer' } },
    'shopify_orders' => { fields: %w[id email created_at total_price currency fulfillment_status financial_status admin_url],
                          inputs: { 'contact_id' => 'integer' } }
  }.freeze
  UNSUPPORTED = %w[external_global_search linear_comments shopify_products shopify_inventory leadsquared_search].freeze

  private

  def virtual_resource?(resource)
    DEFINITIONS.key?(resource)
  end

  def virtual_catalog
    definitions = DEFINITIONS.to_h do |resource, definition|
      resource_gate!(resource)
      [resource, { 'available' => true, 'fields' => definition[:fields],
                   'filters' => virtual_filter_catalog(resource, definition),
                   'relationships' => { 'content' => resource }, 'selection_kind' => 'registered_read', 'orders' => ['oldest'],
                   'limitations' => external_resource?(resource) ? ['upstream_pagination_not_exhaustive'] : [] }]
    rescue Pundit::NotAuthorizedError => e
      [resource, { 'available' => false, 'reason' => e.message }]
    end
    definitions.merge(UNSUPPORTED.index_with { |resource| { 'available' => false, 'reason' => "unsupported_capability:#{resource}" } })
  end

  def virtual_filter_catalog(resource, definition)
    filters = definition[:inputs].transform_values { |type| { 'type' => type, 'operators' => ['eq'] } }
    if resource == 'reports'
      filters['metric']['values'] = Reports::ReportMetricRegistry::METRICS.keys.map(&:to_s)
      filters['dimension']['values'] = %w[account inbox agent team label]
    end
    filters
  end

  def external_resource?(resource)
    resource.start_with?('linear_', 'shopify_')
  end

  def virtual_inputs(resource, filters)
    definition = DEFINITIONS.fetch(resource)
    raise ArgumentError, 'Use at most ten typed filters' unless filters.is_a?(Array) && filters.size <= 10

    filters.each_with_object({}) do |filter, inputs|
      field, operator, value = checked_filter(filter)
      raise ArgumentError, 'Use declared equality inputs' unless operator == 'eq' && definition[:inputs].key?(field) && !inputs.key?(field)

      inputs[field] = checked_value(definition[:inputs].fetch(field), value)
    end
  end

  def select_virtual(resource, fields, filters, order, limit, personal, mention_window) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ParameterLists
    resource_gate!(resource)
    raise ArgumentError, 'Personal and mention predicates are conversation-only' if personal || mention_window
    raise ArgumentError, 'Registered reads require order: oldest (upstream ordering)' unless order == 'oldest'
    raise ArgumentError, 'Limit must be a positive integer' unless limit.nil? || (limit.is_a?(Integer) && limit.positive?)

    fields ||= DEFINITIONS.fetch(resource)[:fields]
    unless fields.is_a?(Array) && fields.any? && fields.all?(String) && (fields - DEFINITIONS.fetch(resource)[:fields]).empty?
      raise ArgumentError, 'Use registered fields only'
    end

    inputs = virtual_inputs(resource, filters)
    # No database snapshot transaction around integration network calls.
    rows, limitations = if external_resource?(resource)
                          Timeout.timeout(Copilot::V2::Limits::EXTERNAL_TIMEOUT) { fetch_external(resource, inputs) }
                        else
                          snapshot { fetch_calculation(resource, inputs) }
                        end
    projection = (['id'] + fields).uniq
    rows = rows.map { |row| row.slice(*projection) }
    validate_native_ids!(resource, rows.pluck('id'))
    raise ArgumentError, 'Upstream returned missing or duplicate identities' if rows.any? do |row|
      row['id'].blank?
    end || rows.pluck('id').uniq.size != rows.size

    requested = limit ? [rows.size, limit].min : rows.size
    selected = rows.first([requested, Copilot::V2::Resources::MAX_SELECTED].min)
    if selected.to_json.bytesize > Copilot::V2::Resources::MAX_SNAPSHOT_BYTES
      raise ArgumentError,
            'Selection metadata exceeds internal byte limit; narrow selection'
    end

    complete = limitations.empty? && selected.size == requested
    { 'reference_type' => 'selection', 'resource' => resource,
      'identity_type' => external_resource?(resource) ? 'external_id' : 'calculation_id', 'selected_ids' => selected.pluck('id'),
      'rows' => selected, 'captured_at' => Time.current.iso8601(6), 'limitations' => limitations,
      'scope' => { 'filters' => filters, 'fields' => fields, 'order' => order, 'requested_limit' => limit },
      'selection' => { 'complete' => complete, 'matching_count' => limitations.empty? ? rows.size : nil,
                       'requested_count' => limitations.empty? ? requested : nil, 'selected_count' => selected.size,
                       'server_cap' => Copilot::V2::Resources::MAX_SELECTED, 'cap_reached' => selected.size < requested,
                       'limitations' => limitations } }
  rescue Timeout::Error
    raise ArgumentError, "external_read_timeout:#{resource}"
  end

  def authorize_virtual!(manifest, ids)
    resource = manifest.fetch('resource')
    resource_gate!(resource)
    inputs = virtual_inputs(resource, manifest.fetch('scope').fetch('filters'))
    case resource
    when 'linear_linked_issues' then scope('conversations').find(inputs.fetch('conversation_id'))
    when 'shopify_orders' then scope('contacts').find(inputs.fetch('contact_id'))
    when 'campaign_metrics' then analytics_campaign!(inputs.fetch('campaign_id'))
    when 'reports' then report_parameters(inputs)
    end
    validate_native_ids!(resource, ids)

    true
  end

  def validate_native_ids!(resource, ids)
    valid = ids.all? do |id|
      resource == 'shopify_orders' ? id.is_a?(Integer) && id.positive? : id.is_a?(String) && id.size.between?(1, 256)
    end
    raise ArgumentError, 'Invalid native identity' unless valid && ids.uniq == ids
  end

  def read_virtual_evidence(selection, relationship, fields, filters, window, customer_only) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/ParameterLists
    unless selection['reference_type'] == 'selection' && relationship == 'content' && filters == [] && window.nil? && customer_only == false
      raise ArgumentError, 'Registered calculation/external evidence requires content relationship without message filters'
    end
    raise ArgumentError, 'Captured external fields cannot be expanded' if fields && (fields - selection.fetch('scope').fetch('fields')).any?

    authorize_manifest!(selection)
    projection = fields ? ['id'] + fields : nil
    items = selection.fetch('rows').map do |row|
      data = projection ? row.slice(*projection) : row
      if data.to_json.bytesize > Copilot::V2::Resources::MAX_EVIDENCE_BYTES
        next { 'id' => row.fetch('id'), 'state' => 'unresolved', 'reason' => 'evidence_too_large', 'records' => [] }
      end

      { 'id' => row.fetch('id'), 'identity' => { 'id' => row.fetch('id') }, 'state' => 'captured',
        'records' => [{ 'id' => row.fetch('id'), 'parts' => [{ 'id' => "#{selection.fetch('resource')}:#{row.fetch('id')}:content",
                                                               'text' => data.to_json, 'provenance' => selection.fetch('resource') }],
                        'limitations' => selection.fetch('limitations', []) }], 'evidence_count' => 1 }
    end
    raise ArgumentError, 'Evidence exceeds internal snapshot limit' if items.to_json.bytesize > Copilot::V2::Resources::MAX_SNAPSHOT_BYTES

    resolved = items.select { |item| item['state'] == 'captured' }.pluck('id')
    unresolved = items.select { |item| item['state'] == 'unresolved' }.pluck('id')
    selection.except('rows').merge('reference_type' => 'evidence', 'evidence_resource' => selection.fetch('resource'),
                                   'relationship' => relationship, 'items' => items,
                                   'complete' => selection.dig('selection', 'complete') && unresolved.empty?,
                                   'resolved_ids' => resolved, 'unresolved_ids' => unresolved,
                                   'retrieved_count' => items.sum { |item| item.fetch('records').size })
  end

  def fetch_calculation(resource, inputs) # rubocop:disable Metrics/AbcSize
    row = case resource
          when 'reports'
            parameters = report_parameters(inputs)
            { 'id' => "report:#{Digest::SHA256.hexdigest(parameters.to_json)}", 'metric' => parameters[:metric],
              'scope' => parameters.as_json, 'value' => V2::Reports::Conversations::ReportBuilder.new(@account, parameters).aggregate_value }
          when 'campaign_metrics'
            campaign = analytics_campaign!(inputs.fetch('campaign_id'))
            recipients = campaign.campaign_recipients
            counts = recipients.group(:status).count
            { 'id' => "campaign:#{campaign.id}:delivery", 'audience' => recipients.count, 'sent' => recipients.where.not(source_id: nil).count,
              'delivered' => counts['delivered'].to_i + counts['read'].to_i, 'read' => counts['read'].to_i,
              'failed' => counts['failed'].to_i, 'skipped' => counts['skipped'].to_i,
              'status_counts' => CampaignRecipient.statuses.keys.index_with { |status| counts[status].to_i } }
          end
    [[row], []]
  end

  def report_parameters(inputs) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    metric = inputs.fetch('metric')
    raise ArgumentError, 'unsupported_capability:report_metric' unless Reports::ReportMetricRegistry.supported?(metric)

    since = inputs.fetch('since')
    ending = inputs.fetch('until')
    raise ArgumentError, 'Report dates must be ordered' unless since <= ending

    dimension = inputs.fetch('dimension', 'account')
    dimension_scopes = { 'inbox' => @account.inboxes, 'agent' => @account.users, 'team' => @account.teams, 'label' => @account.labels }
    raise ArgumentError, 'Unsupported report dimension' unless dimension == 'account' || dimension_scopes.key?(dimension)
    raise ArgumentError, 'Account reports do not accept an authority ID' if dimension == 'account' && inputs.key?('dimension_id')

    dimension_scopes.fetch(dimension).find(inputs.fetch('dimension_id')) unless dimension == 'account'
    { metric: metric, type: dimension.to_sym, id: inputs['dimension_id'], since: since.to_i.to_s, until: ending.to_i.to_s,
      business_hours: inputs.fetch('business_hours', false) }
  end

  def analytics_campaign!(id)
    campaign = scope('campaigns').find(id)
    unless campaign.one_off? && campaign.inbox.inbox_type == 'Whatsapp' && @account.feature_enabled?(:whatsapp_campaign)
      raise Pundit::NotAuthorizedError, 'WhatsApp campaign analytics unavailable'
    end

    campaign
  end
end
