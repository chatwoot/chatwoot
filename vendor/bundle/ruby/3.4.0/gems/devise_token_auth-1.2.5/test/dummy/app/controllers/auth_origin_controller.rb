# frozen_string_literal: true

class AuthOriginController < ApplicationController
  def redirected
    head :ok
  end
end
