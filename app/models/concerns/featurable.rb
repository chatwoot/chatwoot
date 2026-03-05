module Featurable
  extend ActiveSupport::Concern

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  FEATURE_LIST = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze

  FEATURES = FEATURE_LIST.each_with_object({}) do |feature, result|
    result[result.keys.size + 1] = "feature_#{feature['name']}".to_sym
  end

  included do
    include FlagShihTzu
    has_flags FEATURES.merge(column: 'feature_flags').merge(QUERY_MODE)

    # Override FlagShihTzu's generated selected_feature_flags= which expects
    # full flag names (e.g. :feature_agent_bots). Our version accepts short
    # names (e.g. :agent_bots) matching config/features.yml entries.
    define_method(:selected_feature_flags=) do |flags|
      flag_names = flags.map(&:to_s)
      FEATURE_LIST.pluck('name').each do |name|
        send("feature_#{name}=", flag_names.include?(name))
      end
    end

    before_create :enable_default_features
  end

  def enable_features(*names)
    names.each do |name|
      send("feature_#{name}=", true)
    end
  end

  def enable_features!(*names)
    enable_features(*names)
    save
  end

  def disable_features(*names)
    names.each do |name|
      send("feature_#{name}=", false)
    end
  end

  def disable_features!(*names)
    disable_features(*names)
    save
  end

  def feature_enabled?(name)
    send("feature_#{name}?")
  end

  def all_features
    FEATURE_LIST.pluck('name').index_with do |feature_name|
      feature_enabled?(feature_name)
    end
  end

  def enabled_features
    all_features.select { |_feature, enabled| enabled == true }
  end

  def disabled_features
    all_features.select { |_feature, enabled| enabled == false }
  end

  private

  def enable_default_features
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    features_to_enable = if config.present?
                           config.value.select { |f| f[:enabled] }.pluck(:name)
                         else
                           # FlagShihTzu stores flags as bit positions in a signed bigint (max 63 bits).
                           # Enabling all 64 features overflows, so we cap at position 63.
                           FEATURE_LIST.first(63).pluck('name')
                         end

    enable_features(*features_to_enable)
  end
end
