class Api::V1::WhatsappChannelsController < ApplicationController
  def index
    all_channels = Channel::Whatsapp.all
    render json: all_channels
  end
end
