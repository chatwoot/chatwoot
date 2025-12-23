# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking target rails version.
    module TargetRailsVersion
      # Informs the base RuboCop gem that it the Rails version is checked via `requires_gem` API,
      # without needing to call this `#support_target_rails_version` method.
      USES_REQUIRES_GEM_API = true
      # Look for `railties` instead of `rails`, to support apps that only use a subset of `rails`
      # See https://github.com/rubocop/rubocop/pull/11289
      TARGET_GEM_NAME = 'railties' # :nodoc:

      def minimum_target_rails_version(version)
        if respond_to?(:requires_gem)
          case version
          when Integer, Float then requires_gem(TARGET_GEM_NAME, ">= #{version}")
          when String then requires_gem(TARGET_GEM_NAME, version)
          end
        else
          # Fallback path for previous versions of RuboCop which don't support the `requires_gem` API yet.
          @minimum_target_rails_version = version
        end
      end

      def support_target_rails_version?(version)
        if respond_to?(:requires_gem)
          return false unless gem_requirements

          gem_requirement = gem_requirements[TARGET_GEM_NAME]
          return true unless gem_requirement # If we have no requirement, then we support all versions

          gem_requirement.satisfied_by?(Gem::Version.new(version))
        else
          # Fallback path for previous versions of RuboCop which don't support the `requires_gem` API yet.
          @minimum_target_rails_version <= version
        end
      end
    end
  end
end
