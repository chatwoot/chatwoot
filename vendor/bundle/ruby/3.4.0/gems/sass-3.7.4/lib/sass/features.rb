require 'set'
module Sass
  # Provides `Sass.has_feature?` which allows for simple feature detection
  # by providing a feature name.
  module Features
    # This is the set of features that can be detected.
    #
    # When this is updated, the documentation of `feature-exists()` should be
    # updated as well.
    KNOWN_FEATURES = Set[*%w(
      global-variable-shadowing
      extend-selector-pseudoclass
      units-level-3
      at-error
      custom-property
    )]

    # Check if a feature exists by name. This is used to implement
    # the Sass function `feature-exists($feature)`
    #
    # @param feature_name [String] The case sensitive name of the feature to
    #   check if it exists in this version of Sass.
    # @return [Boolean] whether the feature of that name exists.
    def has_feature?(feature_name)
      KNOWN_FEATURES.include?(feature_name)
    end

    # Add a feature to Sass. Plugins can use this to easily expose their
    # availability to end users. Plugins must prefix their feature
    # names with a dash to distinguish them from official features.
    #
    # @example
    #   Sass.add_feature("-import-globbing")
    #   Sass.add_feature("-math-cos")
    #
    #
    # @param feature_name [String] The case sensitive name of the feature to
    #   to add to Sass. Must begin with a dash.
    def add_feature(feature_name)
      unless feature_name[0] == ?-
        raise ArgumentError.new("Plugin feature names must begin with a dash")
      end
      KNOWN_FEATURES << feature_name
    end
  end

  extend Features
end
