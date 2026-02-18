# frozen_string_literal: true

module Crm
  module Hubspot
    module Mappers
      # Maps Nauto Console Contact to HubSpot contact payload
      class ContactMapper
        attr_reader :contact

        def initialize(contact)
          @contact = contact
        end

        # Build HubSpot create/update payload
        #
        # @param custom_fields [Hash] Extra properties to merge
        # @return [Hash] { properties: { firstname:, lastname:, ... } }
        def map_to_contact(custom_fields: {})
          properties = {
            firstname: first_name,
            lastname: last_name,
            hs_lead_status: 'NEW'
          }

          properties[:email] = contact.email if contact.email.present?

          if contact.phone_number.present?
            properties[:phone] = contact.phone_number
            properties[:hs_whatsapp_phone_number] = contact.phone_number
          end

          properties[:company] = contact.account&.name if contact.account&.name.present?

          properties.merge!(custom_fields.transform_keys(&:to_sym)) if custom_fields.present?

          { properties: properties }
        end

        private

        def first_name
          contact.name.to_s.split(' ', 2).first.presence || 'Unknown'
        end

        def last_name
          contact.name.to_s.split(' ', 2)[1].presence || 'Contact'
        end
      end
    end
  end
end
