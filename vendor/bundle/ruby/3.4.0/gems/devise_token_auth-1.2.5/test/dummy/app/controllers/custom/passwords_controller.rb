# frozen_string_literal: true

class Custom::PasswordsController < DeviseTokenAuth::PasswordsController
  def create
    super do |resource|
      @create_block_called = true unless resource.nil?
    end
  end

  def edit
    super do |resource|
      @edit_block_called = true unless resource.nil?
    end
  end

  def update
    super do |resource|
      @update_block_called = true unless resource.nil?
    end
  end

  def create_block_called?
    @create_block_called == true
  end

  def edit_block_called?
    @edit_block_called == true
  end

  def update_block_called?
    @update_block_called == true
  end

  protected

  def render_update_success
    render json: { custom: 'foo' }
  end
end
