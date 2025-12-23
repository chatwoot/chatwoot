# frozen_string_literal: true

class DemoGroupController < ApplicationController
  devise_token_auth_group :member, contains: [:user, :mang]
  before_action :authenticate_member!

  def members_only
    render json: {
      data: {
        message: "Welcome #{current_member.name}",
        user: current_member
      }
    }, status: 200
  end
end
