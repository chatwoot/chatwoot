class Integrations::Linear::ProcessorService
  pattr_initialize [:account!, :conversation!]

  def create_issue; end

  def link_issue; end

  def list_issues
    issues = linear_client.list_issues
    issues.map(&:as_json)
  end

  private

  def linear_hook
    @linear_hook ||= account.hooks.find_by!(app_id: 'linear')
  end

  def linear_client
    credentials = linear_hook.settings
    @linear_client ||= Linear.new(credentials['api_key'])
  end
end
