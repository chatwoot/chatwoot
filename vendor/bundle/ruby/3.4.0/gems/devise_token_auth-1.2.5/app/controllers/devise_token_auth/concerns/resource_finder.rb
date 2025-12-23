# frozen_string_literal: true

module DeviseTokenAuth::Concerns::ResourceFinder
  extend ActiveSupport::Concern
  include DeviseTokenAuth::Controllers::Helpers

  def get_case_insensitive_field_from_resource_params(field)
    # honor Devise configuration for case_insensitive keys
    q_value = resource_params[field.to_sym]

    if resource_class.case_insensitive_keys.include?(field.to_sym)
      q_value.downcase!
    end

    if resource_class.strip_whitespace_keys.include?(field.to_sym)
      q_value.strip!
    end

    q_value
  end

  def find_resource(field, value)
    @resource = if database_adapter&.include?('mysql')
                  # fix for mysql default case insensitivity
                  field_sanitized = resource_class.connection.quote_column_name(field)
                  resource_class.where("BINARY #{field_sanitized} = ? AND provider= ?", value, provider).first
                else
                  resource_class.dta_find_by(field => value, 'provider' => provider)
                end
  end

  def database_adapter
    @database_adapter ||= begin
      rails_version = [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join(".")

      adapter =
        if rails_version >= "6.1"
          resource_class.try(:connection_db_config)&.try(:adapter)
        else
          resource_class.try(:connection_config)&.try(:[], :adapter)
        end
    end
  end

  def resource_class(m = nil)
    mapping = if m
                Devise.mappings[m]
              else
                Devise.mappings[resource_name] || Devise.mappings.values.first
              end

    mapping.to
  end

  def provider
    'email'
  end
end
