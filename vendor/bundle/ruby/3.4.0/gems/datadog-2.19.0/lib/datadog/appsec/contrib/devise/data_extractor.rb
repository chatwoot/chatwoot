# frozen_string_literal: true

require_relative '../../anonymizer'

module Datadog
  module AppSec
    module Contrib
      module Devise
        # Extracts user identification data from Devise resources.
        # Supports both regular and anonymized data extraction modes.
        class DataExtractor
          PRIORITY_ORDERED_ID_KEYS = [:id, 'id', :uuid, 'uuid'].freeze
          PRIORITY_ORDERED_LOGIN_KEYS = [:email, 'email', :username, 'username', :login, 'login'].freeze

          def initialize(mode:)
            @mode = mode
            @devise_scopes = {}
          end

          def extract_id(object)
            return if object.nil?

            if object.respond_to?(:[])
              id = object[PRIORITY_ORDERED_ID_KEYS.find { |key| object[key] }]
              scope = find_devise_scope(object)

              id = "#{scope}:#{id}" if id && scope
              return transform(id)
            end

            id = object.id if object.respond_to?(:id)
            id ||= object.uuid if object.respond_to?(:uuid)

            scope = find_devise_scope(object)
            id = "#{scope}:#{id}" if id && scope

            transform(id)
          end

          def extract_login(object)
            return if object.nil?

            if object.respond_to?(:[])
              login = object[PRIORITY_ORDERED_LOGIN_KEYS.find { |key| object[key] }]
              return transform(login)
            end

            login = object.email if object.respond_to?(:email)
            login ||= object.username if object.respond_to?(:username)
            login ||= object.login if object.respond_to?(:login)

            transform(login)
          end

          private

          def find_devise_scope(object)
            return if ::Devise.mappings.count == 1

            @devise_scopes[object.class.name] ||= ::Devise.mappings
              .each_value.find { |mapping| mapping.class_name == object.class.name }&.name
          end

          def transform(value)
            return if value.nil?
            return value.to_s unless anonymize?

            Anonymizer.anonymize(value.to_s)
          end

          def anonymize?
            @mode == AppSec::Configuration::Settings::ANONYMIZATION_AUTO_USER_INSTRUMENTATION_MODE
          end
        end
      end
    end
  end
end
