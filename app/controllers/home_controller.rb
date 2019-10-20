require 'rest-client'
require 'telegram/bot'
class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:telegram]
  skip_before_action :authenticate_user!, only: [:telegram], raise: false
  skip_before_action :set_current_user
  skip_before_action :check_subscription
  def index; end

  def status
    head :ok
  end
end
