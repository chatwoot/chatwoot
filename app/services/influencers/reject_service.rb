class Influencers::RejectService
  def initialize(profile:, reason: nil)
    @profile = profile
    @reason = reason
  end

  def perform
    @profile.transition_to!(:rejected)
    @profile.update!(rejection_reason: @reason)
    @profile
  end
end
