class SlackUploadsController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :set_blob, only: [:show]

  def show
    if @blob
      redirect_to blob_url
    else
      redirect_to avatar_url
    end
  end

  private

  def set_blob
    @blob = ActiveStorage::Blob.find_by(key: params[:blob_key])
  end

  def blob_url
    url_for(@blob.representation(resize_to_fill: [250, nil]))
  end

  def avatar_url
    base_url = ENV.fetch('FRONTEND_URL', nil)
    "#{base_url}/integrations/slack/#{params[:sender_type]}.png"
  end
end
