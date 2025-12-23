# frozen_string_literal: true

class DemoUserController < ApplicationController
  before_action :authenticate_user!

  def members_only
    render json: {
      data: {
        message: "Welcome #{current_user.name}",
        user: current_user
      }
    }, status: 200
  end

  def members_only_remove_token
    u = User.find(current_user.id)
    u.tokens = {}
    u.save!

    render json: {
      data: {
        message: "Welcome #{current_user.name}",
        user: current_user
      }
    }, status: 200
  end
end
