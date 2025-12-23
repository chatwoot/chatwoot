# frozen_string_literal: true

class Custom::SessionsController < DeviseTokenAuth::SessionsController
  def create
    super do |resource|
      @create_block_called = true unless resource.nil?
    end
  end

  def destroy
    super do |resource|
      @destroy_block_called = true unless resource.nil?
    end
  end

  def create_block_called?
    @create_block_called == true
  end

  def destroy_block_called?
    @destroy_block_called == true
  end

  protected

  def render_create_success
    render json: { custom: 'foo' }
  end
end
