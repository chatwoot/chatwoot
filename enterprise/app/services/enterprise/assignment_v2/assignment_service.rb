module Enterprise::AssignmentV2::AssignmentService
  # Override selector_service to use BalancedSelector when appropriate
  def selector_service
    @selector_service ||= if policy&.balanced?
                            Enterprise::AssignmentV2::BalancedSelector.new(inbox: inbox)
                          else
                            super
                          end
  end

  # Override find_agent_for_conversation to include capacity checks
  def find_agent_for_conversation(_conversation)
    available_agents = inbox.available_agents(
      check_rate_limits: true,
      check_capacity: true
    )

    if available_agents.empty?
      log_no_agents_available
      return nil
    end

    selector_service.select_agent(available_agents)
  end
end
