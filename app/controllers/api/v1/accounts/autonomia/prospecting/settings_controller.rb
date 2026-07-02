class Api::V1::Accounts::Autonomia::Prospecting::SettingsController < Api::V1::Accounts::Autonomia::Prospecting::BaseController
  def show
    render json: { payload: setting }
  end
end
