# Disabled - all enterprise features are permanently enabled
class Internal::ReconcilePlanConfigService
  def perform
    # No-op: Enterprise features are always enabled in this installation
  end
end
