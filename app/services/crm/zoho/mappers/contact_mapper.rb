# frozen_string_literal: true

module Crm
  module Zoho
    module Mappers
      # Maps Nauto Console Contact data to Zoho CRM Lead/Contact format
      class ContactMapper
        attr_reader :contact, :account

        def initialize(contact)
          @contact = contact
          @account = contact.account
        end

        # Map contact to Zoho Lead format
        #
        # @param custom_fields [Hash] Optional custom fields configuration
        # @return [Hash] Zoho Lead data
        def map_to_lead(custom_fields: {})
          data = {
            First_Name: contact.name.presence || 'Unknown',
            Last_Name: contact.last_name.presence || 'Lead',
            Company: company_name,
            Email: contact.email.presence,
            Phone: formatted_phone,
            Lead_Source: 'Nauto Console'
          }.compact

          # Merge custom fields if provided
          data.merge!(map_custom_fields(custom_fields)) if custom_fields.present?

          data
        end

        # Map contact to Zoho Contact format
        #
        # @param owner_id [String] Optional Zoho owner ID
        # @param custom_fields [Hash] Optional custom fields configuration
        # @return [Hash] Zoho Contact data
        def map_to_contact(owner_id: nil, custom_fields: {})
          data = {
            First_Name: contact.name.presence || 'Unknown',
            Last_Name: contact.last_name.presence || 'Contact',
            Email: contact.email.presence,
            Phone: formatted_phone,
            Mobile: formatted_phone,
            Description: "Contact from Nauto Console - Account: #{account.name}",
            Mailing_Street: contact.additional_attributes&.dig('address'),
            Mailing_City: contact.additional_attributes&.dig('city'),
            Mailing_State: contact.additional_attributes&.dig('state'),
            Mailing_Zip: contact.additional_attributes&.dig('postal_code'),
            Mailing_Country: contact.additional_attributes&.dig('country'),
            Lead_Source: 'Nauto Console',
            Email_Opt_Out: false
          }.compact

          # Add owner if specified
          data[:Owner] = { id: owner_id } if owner_id.present?

          # Merge custom fields if provided
          data.merge!(map_custom_fields(custom_fields)) if custom_fields.present?

          data
        end

        # Build search criteria for finding duplicate contacts
        #
        # @return [String] Zoho search criteria
        def search_criteria_by_email
          return nil unless contact.email.present?

          "(Email:equals:#{contact.email})"
        end

        # Build search criteria by phone
        #
        # @return [String] Zoho search criteria
        def search_criteria_by_phone
          return nil unless contact.phone_number.present?

          phone = formatted_phone
          "(Phone:equals:#{phone})or(Mobile:equals:#{phone})"
        end

        private

        def company_name
          account.name || 'Nauto Console'
        end

        def formatted_phone
          return nil unless contact.phone_number.present?

          # Zoho accepts international format
          contact.phone_number
        end

        # Map custom fields from configuration to Zoho format
        #
        # @param custom_fields [Hash] Custom fields configuration
        # @return [Hash] Mapped custom fields
        def map_custom_fields(custom_fields)
          return {} unless custom_fields.is_a?(Hash)

          # Custom fields in Zoho use API names directly
          # Example: { "Custom_Field_1": "value", "Custom_Field_2": "value" }
          custom_fields.transform_keys(&:to_sym)
        end
      end
    end
  end
end
