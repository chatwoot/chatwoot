# Orders the suggested MCP servers for an account. Servers that match something the account already uses come first,
# then the rest in their default order. See enterprise/config/captain_mcp_suggestions.yml for the signals.
class Captain::Mcp::SuggestionsService
  CONFIG_PATH = Rails.root.join('enterprise/config/captain_mcp_suggestions.yml')
  # Signals that match a value exactly, and signals that match when the account's text contains the value
  EXACT_SIGNALS = { 'hooks' => :hook_ids, 'industries' => :industries, 'subindustries' => :subindustries }.freeze
  CONTAINS_SIGNALS = { 'hosts' => :hosts, 'attribute_keywords' => :attribute_keys }.freeze

  def self.suggestions
    @suggestions ||= YAML.load_file(CONFIG_PATH).freeze
  end

  def initialize(account)
    @account = account
  end

  def perform
    self.class.suggestions.each_with_index
        .map { |suggestion, index| [suggestion.except('signals').merge('recommended' => matches?(suggestion['signals'] || {})), index] }
        .sort_by { |suggestion, index| [suggestion['recommended'] ? 0 : 1, index] }
        .map(&:first)
  end

  private

  def matches?(signals)
    signals.any? { |name, values| Array(values).any? { |value| signal_match?(name, value) } }
  end

  # An unknown signal name in the config raises, so a typo cannot silently drop a suggestion's signals
  def signal_match?(name, value)
    return send(EXACT_SIGNALS[name]).include?(value) if EXACT_SIGNALS.key?(name)

    send(CONTAINS_SIGNALS.fetch(name)).any? { |text| text.include?(value) }
  end

  def hook_ids
    @hook_ids ||= @account.hooks.distinct.pluck(:app_id)
  end

  def hosts
    @hosts ||= (@account.webhooks.pluck(:url) + Channel::Api.where(account_id: @account.id).pluck(:webhook_url) +
               Captain::CustomTool.where(account_id: @account.id).pluck(:endpoint_url)).filter_map { |url| url_host(url) }.uniq
  end

  def url_host(url)
    URI.parse(url.to_s).host&.downcase
  rescue URI::InvalidURIError
    nil
  end

  def industries
    @industries ||= [@account.custom_attributes['industry'], *brand_industries.pluck('industry')].compact
  end

  def subindustries
    @subindustries ||= brand_industries.pluck('subindustry').compact
  end

  def brand_industries
    @brand_industries ||= Array(@account.custom_attributes.dig('brand_info', 'industries')).grep(Hash)
  end

  def attribute_keys
    @attribute_keys ||= @account.custom_attribute_definitions.pluck(:attribute_key).map(&:downcase)
  end
end
