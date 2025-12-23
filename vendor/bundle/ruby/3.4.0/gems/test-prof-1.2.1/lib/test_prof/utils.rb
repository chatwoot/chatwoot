# frozen_string_literal: true

module TestProf
  module Utils # :nodoc:
    class << self
      # Verify that loaded gem has correct version
      def verify_gem_version(gem_name, at_least: nil, at_most: nil)
        raise ArgumentError, "Please, provide `at_least` or `at_most` argument" if
          at_least.nil? && at_most.nil?

        spec = Gem.loaded_specs[gem_name]
        version = spec.version if spec
        return false if version.nil?

        supported_version?(version, at_least, at_most)
      end

      def supported_version?(gem_version, at_least, at_most)
        (at_least.nil? || Gem::Version.new(at_least) <= gem_version) &&
          (at_most.nil? || Gem::Version.new(at_most) >= gem_version)
      end
    end
  end
end
