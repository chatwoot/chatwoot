# frozen_string_literal: true

module Crm
  module Salesforce
    module Mappers
      # Maps Nauto Console Contact data to Salesforce Lead/Contact format
      class ContactMapper
        attr_reader :contact, :account

        def initialize(contact)
          @contact = contact
          @account = contact.account
        end

        # Map contact to Salesforce Lead format
        #
        # @param custom_fields [Hash] Optional custom fields configuration
        # @return [Hash] Salesforce Lead data
        def map_to_lead(custom_fields: {})
          data = {
            FirstName: contact.name.presence || 'Unknown',
            LastName: contact.last_name.presence || 'Lead',
            Company: company_name,
            Email: contact.email.presence,
            Phone: formatted_phone,
            MobilePhone: formatted_phone,
            Street: contact.additional_attributes&.dig('address'),
            City: contact.additional_attributes&.dig('city'),
            State: contact.additional_attributes&.dig('state'),
            PostalCode: contact.additional_attributes&.dig('postal_code'),
            Country: contact.additional_attributes&.dig('country'),
            LeadSource: 'Nauto Console',
            Status: 'Open - Not Contacted'
          }.compact

          # Merge custom fields if provided
          data.merge!(map_custom_fields(custom_fields)) if custom_fields.present?

          data
        end

        # Map contact to Salesforce Contact format
        #
        # @param account_id [String] Optional Salesforce Account ID
        # @param custom_fields [Hash] Optional custom fields configuration
        # @return [Hash] Salesforce Contact data
        def map_to_contact(account_id: nil, custom_fields: {})
          data = {
            FirstName: contact.name.presence || 'Unknown',
            LastName: contact.last_name.presence || 'Contact',
            Email: contact.email.presence,
            Phone: formatted_phone,
            MobilePhone: formatted_phone,
            Description: "Contact from Nauto Console - Account: #{account.name}",
            MailingStreet: contact.additional_attributes&.dig('address'),
            MailingCity: contact.additional_attributes&.dig('city'),
            MailingState: contact.additional_attributes&.dig('state'),
            MailingPostalCode: contact.additional_attributes&.dig('postal_code'),
            MailingCountry: contact.additional_attributes&.dig('country'),
            LeadSource: 'Nauto Console'
          }.compact

          # Link to Salesforce Account if provided
          data[:AccountId] = account_id if account_id.present?

          # Merge custom fields if provided
          data.merge!(map_custom_fields(custom_fields)) if custom_fields.present?

          data
        end

        private

        def company_name
          account.name || 'Nauto Console'
        end

        def formatted_phone
          return nil unless contact.phone_number.present?

          # Salesforce accepts international format
          contact.phone_number
        end

        # Map custom fields from configuration to Salesforce format
        #
        # @param custom_fields [Hash] Custom fields configuration
        # @return [Hash] Mapped custom fields
        def map_custom_fields(custom_fields)
          return {} unless custom_fields.is_a?(Hash)

          # Custom fields in Salesforce use API names with __c suffix
          # Example: { "Custom_Field__c": "value" }
          custom_fields.transform_keys(&:to_sym)
        end
      end
    end
  end
end
