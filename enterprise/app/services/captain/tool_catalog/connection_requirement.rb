class Captain::ToolCatalog::ConnectionRequirement
  Result = Struct.new(:hook, :missing_scopes, keyword_init: true) do
    def satisfied?
      hook&.enabled? && missing_scopes.empty?
    end
  end

  def initialize(account:)
    @account = account
  end

  def check(provider_key:, required_scopes:)
    hook = account.hooks.account_hooks.find_by(app_id: provider_key)
    Result.new(
      hook: hook,
      missing_scopes: Array(required_scopes) - granted_scopes(hook)
    )
  end

  private

  attr_reader :account

  def granted_scopes(hook)
    return [] if hook.blank?

    settings = hook.settings.to_h.with_indifferent_access
    value = settings[:scopes].presence || settings[:scope]
    scopes = value.is_a?(String) ? value.split(/[\s,]+/) : Array(value)
    scopes.filter_map { |scope| scope.to_s.presence }.uniq
  end
end
