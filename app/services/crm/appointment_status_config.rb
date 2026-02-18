# frozen_string_literal: true

module Crm
  # Configuration for mapping Chatwoot appointment statuses to CRM-specific status values
  #
  # Each CRM has different status terminology and available values:
  # - Zoho: Scheduled, In Progress, Completed, Cancelled (no no_show)
  # - Salesforce: Planned, In Progress, Completed, Cancelled, No Show
  # - HubSpot: SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW
  #
  # This configuration centralizes the status mapping logic.
  class AppointmentStatusConfig
    # Mapping structure:
    # {
    #   'crm_name' => {
    #     'chatwoot_status' => 'crm_status_value'
    #   }
    # }
    MAPPINGS = {
      'zoho' => {
        'scheduled' => 'Scheduled',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        'no_show' => 'Cancelled' # Zoho no tiene no_show, se mapea a Cancelled
      },
      'salesforce' => {
        'scheduled' => 'Planned',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        'no_show' => 'No Show'
      },
      'hubspot' => {
        'scheduled' => 'SCHEDULED',
        'in_progress' => 'IN_PROGRESS',
        'completed' => 'COMPLETED',
        'cancelled' => 'CANCELLED',
        'no_show' => 'NO_SHOW'
      },
      'leadsquared' => {
        'scheduled' => 'Pending',
        'in_progress' => 'In Progress',
        'completed' => 'Completed',
        'cancelled' => 'Cancelled',
        'no_show' => 'Cancelled' # LeadSquared no tiene no_show
      }
    }.freeze

    # Resolve the CRM status value for a given Chatwoot status
    #
    # @param crm_name [String] CRM identifier ('zoho', 'salesforce', 'hubspot')
    # @param chatwoot_status [String] Chatwoot status ('scheduled', 'in_progress', 'completed', 'cancelled', 'no_show')
    # @return [String, nil] CRM status value, or nil if not found
    #
    # @example
    #   Crm::AppointmentStatusConfig.resolve('zoho', 'scheduled')
    #   # => 'Scheduled'
    #
    #   Crm::AppointmentStatusConfig.resolve('salesforce', 'no_show')
    #   # => 'No Show'
    #
    #   Crm::AppointmentStatusConfig.resolve('zoho', 'no_show')
    #   # => 'Cancelled' (fallback because Zoho doesn't have no_show)
    def self.resolve(crm_name, chatwoot_status)
      MAPPINGS.dig(crm_name, chatwoot_status)
    end

    # Get all Chatwoot statuses
    #
    # @return [Array<String>] List of Chatwoot appointment statuses
    def self.chatwoot_statuses
      %w[scheduled in_progress completed cancelled no_show]
    end

    # Get all CRM status values for a specific CRM
    #
    # @param crm_name [String] CRM identifier
    # @return [Hash] Mapping of Chatwoot status to CRM status
    def self.mappings_for(crm_name)
      MAPPINGS[crm_name] || {}
    end

    # Check if a CRM supports status mapping
    #
    # @param crm_name [String] CRM identifier
    # @return [Boolean]
    def self.supported?(crm_name)
      MAPPINGS.key?(crm_name)
    end
  end
end
