module Enterprise::AssignmentV2::AssignmentService
  # Override selector_service to use BalancedSelector when appropriate
  def selector_service
    @selector_service ||= if policy&.balanced?
                            Enterprise::AssignmentV2::BalancedSelector.new(inbox: inbox)
                          else
                            super
                          end
  end
end
