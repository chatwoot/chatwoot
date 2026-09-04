class Captain::ToolsetExporter
  def initialize(tool)
    @tool = tool
  end

  def to_yaml
    YAML.dump(manifest)
  end

  private

  attr_reader :tool

  def manifest
    auth_config, inputs, secrets = authentication
    {
      'version' => Captain::ToolsetService::DEFAULT_VERSION,
      'kind' => Captain::ToolsetService::KIND,
      'name' => tool.title,
      'description' => tool.description,
      'inputs' => inputs,
      'secrets' => secrets,
      'tools' => [tool_definition(auth_config)]
    }.compact
  end

  def tool_definition(auth_config)
    {
      'id' => tool.slug,
      'title' => tool.title,
      'description' => tool.description,
      'http_method' => tool.http_method,
      'endpoint_url' => tool.endpoint_url,
      'auth_type' => tool.auth_type,
      'auth_config' => auth_config,
      'param_schema' => tool.param_schema,
      'request_template' => tool.request_template,
      'response_template' => tool.response_template,
      'enabled' => tool.enabled
    }.compact
  end

  def authentication
    case tool.auth_type
    when 'bearer'
      [{ 'token' => '${{ secrets.bearer_token }}' }, {}, definition('bearer_token', 'Bearer token')]
    when 'basic'
      basic_authentication
    when 'api_key'
      [{ 'name' => tool.auth_config['name'], 'key' => '${{ secrets.api_key }}' }, {}, definition('api_key', 'API key')]
    else
      [{}, {}, {}]
    end
  end

  def basic_authentication
    [
      { 'username' => '${{ inputs.username }}', 'password' => '${{ secrets.password }}' },
      definition('username', 'Username'),
      definition('password', 'Password')
    ]
  end

  def definition(name, label)
    { name => { 'label' => label, 'required' => true } }
  end
end
