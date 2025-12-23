# frozen_string_literal: true

class Custom::OmniauthCallbacksController < DeviseTokenAuth::OmniauthCallbacksController
  def omniauth_success
    super do |resource|
      @omniauth_success_block_called = true unless resource.nil?
    end
  end

  def omniauth_success_block_called?
    @omniauth_success_block_called == true
  end
end
