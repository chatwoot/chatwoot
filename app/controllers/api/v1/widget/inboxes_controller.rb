class Api::V1::Widget::InboxesController < ApplicationController

  def create
    
  end

  private

  def permitted_params
    params.fetch(:website).permit(:website_name, :website_url)
  end
end
