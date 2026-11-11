class Keycloak::PermissionMap
  CONFIG_PATH = Rails.root.join('config/keycloak_permissions.yml')
  ROLE_PREFIX = 'keycloak:'.freeze

  class << self
    def config
      @config ||= YAML.safe_load_file(CONFIG_PATH).with_indifferent_access
    end

    def reload!
      @config = nil
    end

    def capabilities
      config[:capabilities]
    end

    def default_agent_capabilities
      config[:default_agent_capabilities] || []
    end

    # Returns nil when none of the given Keycloak roles are mapped.
    def resolve(keycloak_roles)
      mapped = Array(keycloak_roles).filter_map { |role| config[:roles][normalize(role)] }
      return nil if mapped.empty?

      {
        administrator: mapped.any? { |entry| entry[:administrator] },
        permissions: (mapped.flat_map { |entry| entry[:permissions] || [] } & capabilities).uniq
      }
    end

    def normalize(role)
      role.to_s.delete_prefix(ROLE_PREFIX)
    end
  end
end
