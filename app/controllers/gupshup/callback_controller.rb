class Gupshup::CallbackController < ApplicationController
  def create
    if params['payload']['phone'] == 'callbackSetPhone'
      Rails.logger.info 'Gupshup callback set'
      true
    else
      Rails.logger.info 'Gupshup event recieved'
      puts permitted_params
      ::Gupshup::IncomingMessageService.new(params: permitted_params).perform
      head :no_content
    end


  end

  private

  def permitted_params
    params.permit(
      :app,
      :timestamp,
      :version,
      :type,
      :sender,
      :context,
      :channel,
      :source,
      'src.name',
      :message,
      :payload => [:id, :source, :text, :payload=>[:text], :sender => [:phone, :name]]
    )
  end
end
