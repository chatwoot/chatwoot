class Auth::DeskUsersController < ActionController::API
  # Public list of reception-desk agents for the name dropdown on /app/login/desk.
  # Only returns id + display name (no emails).
  def index
    users = User.with_desk_login.order(:name).select(:id, :name)
    render json: {
      payload: users.map { |user| { id: user.id, name: user.name } }
    }
  end
end
