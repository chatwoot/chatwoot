# frozen_string_literal: true

module CrmFlows
  # Resolves CRM owner ID from different sources with priority
  # Priority: metadata > appointment.owner > conversation.assignee > default
  class OwnerResolver
    def initialize(account:, conversation: nil, appointment: nil, metadata: {})
      @account = account
      @conversation = conversation
      @appointment = appointment
      @metadata = metadata
      @cache = {}
    end

    # Resolve owner ID from available sources
    #
    # @return [String, nil] CRM external ID or nil
    def resolve
      # Priority 1: Explicit owner_id in metadata (highest priority)
      return @metadata[:owner_id] if @metadata[:owner_id].present?
      return @metadata['owner_id'] if @metadata['owner_id'].present?

      # Priority 2: Appointment owner (for appointment-related actions)
      if @appointment&.owner
        owner_id = resolve_from_user(@appointment.owner)
        return owner_id if owner_id.present?
      end

      # Priority 3: Conversation assignee (for advisor transfers)
      if @conversation&.assignee
        owner_id = resolve_from_user(@conversation.assignee)
        return owner_id if owner_id.present?
      end

      # No owner found
      Rails.logger.debug "[OwnerResolver] No CRM owner found for resolution"
      nil
    end

    # Check if owner resolution is possible
    #
    # @return [Boolean]
    def resolvable?
      @metadata[:owner_id].present? ||
        @metadata['owner_id'].present? ||
        @appointment&.owner.present? ||
        @conversation&.assignee.present?
    end

    private

    # Resolve CRM owner ID from a user
    # Uses cache to avoid repeated queries
    #
    # @param user [User] The user
    # @return [String, nil] CRM external ID
    def resolve_from_user(user)
      return nil unless user

      # Use cache to avoid repeated queries
      @cache[user.id] ||= begin
        account_user = user.account_users.find_by(account_id: @account.id)
        crm_external_id = account_user&.crm_external_id

        if crm_external_id.blank?
          Rails.logger.warn "⚠️  [OwnerResolver] User #{user.email} (#{user.id}) is not synced with CRM"
        else
          Rails.logger.debug "✓ [OwnerResolver] Resolved owner: #{user.email} → CRM ID: #{crm_external_id}"
        end

        crm_external_id
      end
    end
  end
end
