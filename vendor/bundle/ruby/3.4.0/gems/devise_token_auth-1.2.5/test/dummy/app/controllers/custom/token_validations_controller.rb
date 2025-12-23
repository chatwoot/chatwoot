# frozen_string_literal: true

class Custom::TokenValidationsController < DeviseTokenAuth::TokenValidationsController
  def validate_token
    super do |resource|
      @validate_token_block_called = true unless resource.nil?
    end
  end

  def validate_token_block_called?
    @validate_token_block_called == true
  end

  protected

  def render_validate_token_success
    render json: { custom: 'foo' }
  end
end
