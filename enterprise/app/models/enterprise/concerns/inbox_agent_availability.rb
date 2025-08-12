# frozen_string_literal: true

module Enterprise::Concerns::InboxAgentAvailability
  def apply_agent_filters(scope, options)
    scope = super(scope, options)

    # Apply capacity filtering if requested
    scope = filter_by_capacity(scope) if options[:check_capacity]

    scope
  end

  private

  def filter_by_capacity(inbox_members_scope)
    return inbox_members_scope unless assignment_policy&.enabled?

    inbox_members_scope.select do |inbox_member|
      account_user = AccountUser.find_by(account: account, user: inbox_member.user)
      next true if account_user&.agent_capacity_policy.blank?

      capacity_service = Enterprise::AssignmentV2::CapacityService.new(account_user)
      capacity_service.agent_has_capacity?(self)
    end
  end
end
