module Featurable
  extend ActiveSupport::Concern

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  FEATURE_LIST = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze

  all_features_mapped = FEATURE_LIST.each_with_index.map do |feature, index|
    [index + 1, "feature_#{feature['name']}".to_sym]
  end.to_h

  # We split at 63 because 64 is the sign bit in some implementations, 
  # and staying safe avoids range issues.
  FEATURES_1 = all_features_mapped.select { |k, _v| k <= 63 }
  FEATURES_2 = all_features_mapped.select { |k, _v| k > 63 }.transform_keys { |k| k - 63 }

  included do
    include FlagShihTzu
    has_flags FEATURES_1.merge(column: 'feature_flags').merge(QUERY_MODE)

    # Only load second column flags if the database column actually exists
    # This prevents failures during the migration process itself
    # Always load second column flags if defined in configuration
    if FEATURES_2.present?
      has_flags FEATURES_2.merge(column: 'feature_flags_2').merge(QUERY_MODE)
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
    return true if config.blank?

    features_to_enabled = config.value.select { |f| f[:enabled] }.pluck(:name)
    enable_features(*features_to_enabled)
  end
end
