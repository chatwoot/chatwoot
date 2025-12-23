# frozen_string_literal: true

class Custom::ConfirmationsController < DeviseTokenAuth::ConfirmationsController
  def show
    super do |resource|
      @show_block_called = true unless resource.nil?
    end
  end

  def show_block_called?
    @show_block_called == true
  end
end
