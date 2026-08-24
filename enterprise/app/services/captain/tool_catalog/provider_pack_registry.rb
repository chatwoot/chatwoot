class Captain::ToolCatalog::ProviderPackRegistry
  DEFAULT_PROVIDERS_PATH = Rails.root.join('enterprise/config/captain/tool_catalog/providers').freeze

  def self.default
    @default ||= new
  end

  def initialize(providers_path: DEFAULT_PROVIDERS_PATH)
    @providers_path = Pathname(providers_path)
  end

  def all
    @all ||= compile_packs
  end

  def find(provider_key)
    providers_by_key.fetch(provider_key) do
      raise ActiveRecord::RecordNotFound, "Unknown Captain tool catalog provider: #{provider_key}"
    end
  end

  private

  attr_reader :providers_path

  def providers_by_key
    @providers_by_key ||= all.index_by { |pack| pack.dig('provider', 'key') }.freeze
  end

  def compile_packs
    packs = pack_paths.map { |path| Captain::ToolCatalog::ProviderPackCompiler.new(pack_path: path).compile }
    duplicate_keys = packs.group_by { |pack| pack.dig('provider', 'key') }.select { |_key, values| values.many? }.keys
    raise Captain::ToolCatalog::ProviderPackError, "Duplicate provider keys: #{duplicate_keys.sort.join(', ')}" if duplicate_keys.any?

    packs.sort_by { |pack| pack.dig('provider', 'key') }.freeze
  end

  def pack_paths
    return [] unless providers_path.directory?

    providers_path.glob('*/manifest.yml').map(&:dirname).sort
  end
end
