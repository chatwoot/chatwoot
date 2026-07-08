module Featurable
  extend ActiveSupport::Concern

  DEFAULT_FEATURE_FLAG_COLUMN = 'feature_flags'.freeze
  FEATURE_FLAG_COLUMNS = [DEFAULT_FEATURE_FLAG_COLUMN, 'feature_flags_ext_1'].freeze
  MAX_FEATURES_PER_COLUMN = 63

  QUERY_MODE = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  FEATURE_LIST = YAML.safe_load(Rails.root.join('config/features.yml').read).freeze

  def self.feature_flag_mappings_for(feature_list)
    features_by_column = feature_list.group_by { |feature| feature['column'].presence || DEFAULT_FEATURE_FLAG_COLUMN }

    mappings = FEATURE_FLAG_COLUMNS.index_with do |column|
      features = features_by_column.delete(column) || []
      validate_feature_count!(column, features)

      features.each_with_index.to_h do |feature, index|
        [index + 1, "feature_#{feature['name']}".to_sym]
      end
    end

    validate_feature_columns!(features_by_column)
    mappings
  end

  def self.validate_feature_count!(column, features)
    return if features.size <= MAX_FEATURES_PER_COLUMN

    raise ArgumentError, "Account feature flag column #{column} supports up to #{MAX_FEATURES_PER_COLUMN} features"
  end

  def self.validate_feature_columns!(features_by_column)
    return if features_by_column.blank?

    invalid_columns = features_by_column.keys.join(', ')
    raise ArgumentError, "Unknown account feature flag column: #{invalid_columns}"
  end

  FEATURES_BY_COLUMN = feature_flag_mappings_for(FEATURE_LIST).freeze

  included do
    include FlagShihTzu

    FEATURE_FLAG_COLUMNS.each do |column|
      has_flags FEATURES_BY_COLUMN.fetch(column).merge(column: column).merge(QUERY_MODE)
    end

    before_create :enable_default_features

    define_method :all_feature_flags do
      FEATURE_FLAG_COLUMNS.flat_map { |column| all_flags(column) }
    end

    define_method :selected_feature_flags do
      FEATURE_FLAG_COLUMNS.flat_map { |column| selected_flags(column) }
    end

    define_method :selected_feature_flags= do |chosen_flags|
      FEATURE_FLAG_COLUMNS.each { |column| unselect_all_flags(column) }
      return if chosen_flags.nil?

      chosen_flags.each do |selected_flag|
        enable_flag(selected_flag.to_sym) if selected_flag.present?
      end
    end
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
