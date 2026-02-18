# frozen_string_literal: true

module Crm
  module Concerns
    # Concern for CRM services that support owner assignment
    # Provides common methods for updating lead/contact owners
    module OwnerAssignable
      extend ActiveSupport::Concern

      # Add owner to data hash if owner_id is provided
      #
      # @param data [Hash] The data hash to modify
      # @param params [Hash] Parameters containing optional owner_id
      # @param action [String] Action name for logging
      # @return [Hash] Modified data hash
      def add_owner_to_data(data, params, action: 'action')
        return data unless params[:owner_id].present?

        data[:Owner] = { id: params[:owner_id] }
        Rails.logger.info "✓ [#{action.upcase}] Setting owner to CRM ID: #{params[:owner_id]}"
        data
      end

      # Validate that owner_id exists in CRM (optional, can be overridden)
      #
      # @param owner_id [String] CRM owner ID
      # @return [Boolean] True if valid (default implementation always returns true)
      def valid_owner_id?(owner_id)
        # Subclasses can override to validate against CRM API
        owner_id.present?
      end

      # Log owner assignment
      #
      # @param action [String] Action being performed
      # @param owner_id [String] CRM owner ID
      # @param record_id [String] CRM record ID
      def log_owner_assignment(action, owner_id, record_id)
        if owner_id.present?
          Rails.logger.info "✓ [#{action.upcase}] Assigned owner #{owner_id} to record #{record_id}"
        end
      end
    end
  end
end
