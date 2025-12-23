# frozen_string_literal: true

require 'json'

# Internal: Verifies that the installed vite-plugin-ruby version is compatible
# with the current version of vite_ruby.
#
# This helps to prevent more subtle runtime errors if there is a mismatch in the
# manifest schema.
module ViteRuby::CompatibilityCheck
  class << self
    # Public: Attempt to verify that the vite-plugin-ruby version is compatible.
    def verify_plugin_version(root)
      package = JSON.parse(root.join('package.json').read) rescue {}
      requirement = package.dig('devDependencies', 'vite-plugin-ruby') ||
                    package.dig('dependencies', 'vite-plugin-ruby')

      raise_unless_satisfied(requirement, ViteRuby::DEFAULT_PLUGIN_VERSION)
    end

    # Internal: Notifies the user of a possible incompatible plugin.
    def raise_unless_satisfied(npm_req, ruby_req)
      unless compatible_plugin?(npm_req, ruby_req)
        raise ArgumentError, <<~ERROR
          vite-plugin-ruby@#{ npm_req } might not be compatible with vite_ruby-#{ ViteRuby::VERSION }

          You may disable this check if needed: https://vite-ruby.netlify.app/config/#skipcompatibilitycheck

          You may upgrade both by running:

              bundle exec vite upgrade
        ERROR
      end
    end

    # Internal: Returns true unless the check is performed and does not meet the
    # requirement.
    def compatible_plugin?(npm_req, ruby_req)
      npm_req, ruby_req = [npm_req, ruby_req]
        .map { |req| Gem::Requirement.new(req.sub('^', '~>')) }

      current_version = npm_req.requirements.first.second

      ruby_req.satisfied_by?(current_version)
    rescue StandardError
      true
    end
  end
end
