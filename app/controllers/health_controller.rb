class HealthController < ActionController::Base
  def show
    render json: { status: 'woot' }
  end
end
