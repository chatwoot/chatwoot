module Enterprise::SuperAdmin::UserDiagnosticsController
  private

  def load_diagnostics
    super
    @ring_readiness = Voice::RingReadiness.new(user: @user) if @user
  end
end
