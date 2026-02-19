# Disabled - no external version checks or plan updates from Chatwoot hub
module Enterprise::Internal::CheckNewVersionsJob
  def perform
    # No-op: External connections disabled
  end
end
