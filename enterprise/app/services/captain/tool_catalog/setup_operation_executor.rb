class Captain::ToolCatalog::SetupOperationExecutor
  ALLOWED_OPERATIONS = {
    'linear' => {
      'list_teams' => [],
      'list_team_entities' => ['teamId']
    },
    'slack' => {
      'list_channels' => []
    }
  }.freeze
  MAX_OPTIONS = 100
  ToolContext = Struct.new(:provider_key, :definition, :integration_hook, keyword_init: true)

  def initialize(account:, registry: Captain::ToolCatalog::ProviderPackRegistry.default)
    @account = account
    @registry = registry
  end

  def perform(provider_key:, operation_key:, arguments: {})
    pack = registry.find(provider_key)
    operation = setup_operation!(pack, provider_key, operation_key)
    normalized_arguments = validate_arguments!(provider_key, operation_key, arguments)
    requirement = Captain::ToolCatalog::ConnectionRequirement.new(account: account).check(
      provider_key: provider_key,
      required_scopes: operation.fetch('scopes')
    )
    raise Captain::ToolCatalog::WorkflowError, 'setup_connection_required' unless requirement.satisfied?

    result = Captain::ToolCatalog::HttpClient.new(
      custom_tool: tool_context(pack, provider_key, requirement.hook),
      operation: operation
    ).perform(request_arguments(provider_key, operation_key, normalized_arguments))
    project(provider_key, operation_key, result)
  rescue Captain::ToolCatalog::ExecutionError => e
    raise Captain::ToolCatalog::WorkflowError, e.code
  end

  private

  attr_reader :account, :registry

  def setup_operation!(pack, provider_key, operation_key)
    allowed_arguments = ALLOWED_OPERATIONS.dig(provider_key, operation_key)
    operation = pack.fetch('operations').find { |candidate| candidate.fetch('key') == operation_key }
    return operation if allowed_arguments && operation&.fetch('visibility') == 'setup'

    raise Captain::ToolCatalog::WorkflowError, 'setup_operation_not_found'
  end

  def validate_arguments!(provider_key, operation_key, arguments)
    normalized = arguments.to_h.stringify_keys
    expected = ALLOWED_OPERATIONS.fetch(provider_key).fetch(operation_key)
    raise Captain::ToolCatalog::WorkflowError, 'invalid_setup_arguments' unless normalized.keys.sort == expected.sort
    return normalized if normalized.empty?
    return normalized if normalized.values.all? { |value| value.is_a?(String) && value.match?(/\A[a-zA-Z0-9-]{1,100}\z/) }

    raise Captain::ToolCatalog::WorkflowError, 'invalid_setup_arguments'
  end

  def request_arguments(provider_key, operation_key, arguments)
    return arguments unless provider_key == 'slack' && operation_key == 'list_channels'

    { 'types' => 'public_channel,private_channel', 'exclude_archived' => true, 'limit' => MAX_OPTIONS }
  end

  def tool_context(pack, provider_key, hook)
    ToolContext.new(
      provider_key: provider_key,
      definition: { 'allowed_origins' => pack.fetch('allowed_origins') },
      integration_hook: hook
    )
  end

  def project(provider_key, operation_key, result)
    return project_slack_channels(result) if provider_key == 'slack'
    return project_linear_teams(result) if operation_key == 'list_teams'

    project_linear_team_entities(result)
  end

  def project_slack_channels(result)
    {
      'options' => Array(result['channels']).first(MAX_OPTIONS).map do |channel|
        channel.slice('id', 'name', 'is_private')
      end
    }
  end

  def project_linear_teams(result)
    { 'options' => project_named_nodes(result.dig('teams', 'nodes')) }
  end

  def project_linear_team_entities(result)
    {
      'team' => result['team'].to_h.slice('id', 'name'),
      'projects' => project_named_nodes(result.dig('projects', 'nodes'))
    }
  end

  def project_named_nodes(nodes)
    Array(nodes).first(MAX_OPTIONS).map { |node| node.slice('id', 'name') }
  end
end
