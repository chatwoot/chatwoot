# frozen_string_literal: true

module Crm
  # Configuration for mapping Chatwoot appointment types to CRM-specific objects
  #
  # Each CRM handles appointments differently:
  # - Zoho: separate objects for Calls, Events, Meetings
  # - Salesforce: Tasks for calls, Events for meetings
  # - HubSpot: unified Meeting object for all types
  #
  # This configuration centralizes the mapping logic, making it easy to:
  # - Add new CRMs (just add a new entry)
  # - Modify mappings without changing code
  # - See all mappings in one place
  class AppointmentTypeConfig
    # Mapping structure:
    # {
    #   'crm_name' => {
    #     'appointment_type' => {
    #       object: 'crm_object_name',
    #       action: 'processor_method_name'
    #     }
    #   }
    # }
    MAPPINGS = {
      'zoho' => {
        'phone_call' => { object: 'call', action: 'create_call' },
        'digital_meeting' => { object: 'event', action: 'create_event' },
        'physical_visit' => { object: 'event', action: 'create_event' }
      },
      'salesforce' => {
        'phone_call' => { object: 'task', action: 'create_task' },
        'digital_meeting' => { object: 'event', action: 'create_event' },
        'physical_visit' => { object: 'event', action: 'create_event' }
      },
      'hubspot' => {
        'phone_call' => { object: 'meeting', action: 'create_meeting' },
        'digital_meeting' => { object: 'meeting', action: 'create_meeting' },
        'physical_visit' => { object: 'meeting', action: 'create_meeting' }
      },
      'leadsquared' => {
        'phone_call' => { object: 'task', action: 'create_task' },
        'digital_meeting' => { object: 'task', action: 'create_task' },
        'physical_visit' => { object: 'task', action: 'create_task' }
      }
    }.freeze

    # Resolve the CRM object and action for a given appointment type
    #
    # @param crm_name [String] CRM identifier ('zoho', 'salesforce', 'hubspot')
    # @param appointment_type [String] Appointment type ('phone_call', 'digital_meeting', 'physical_visit')
    # @return [Hash, nil] Configuration hash with :object and :action keys, or nil if not found
    #
    # @example
    #   Crm::AppointmentTypeConfig.resolve('zoho', 'phone_call')
    #   # => { object: 'call', action: 'create_call' }
    #
    #   Crm::AppointmentTypeConfig.resolve('salesforce', 'phone_call')
    #   # => { object: 'task', action: 'create_task' }
    def self.resolve(crm_name, appointment_type)
      MAPPINGS.dig(crm_name, appointment_type)
    end

    # Get all supported CRMs
    #
    # @return [Array<String>] List of CRM identifiers
    def self.supported_crms
      MAPPINGS.keys
    end

    # Check if a CRM is supported
    #
    # @param crm_name [String] CRM identifier
    # @return [Boolean]
    def self.supported?(crm_name)
      MAPPINGS.key?(crm_name)
    end

    # Get all appointment types for a CRM
    #
    # @param crm_name [String] CRM identifier
    # @return [Array<String>] List of appointment types
    def self.appointment_types_for(crm_name)
      MAPPINGS.dig(crm_name)&.keys || []
    end
  end
end
