class Gupshup::CallbackController < ApplicationController
  def create
    if params['payload']['phone'] == 'callbackSetPhone' # Logs callback Url verification from gupshup dashboard
      Rails.logger.info 'GUPSHUP CALLBACK: Url set'
    elsif ['delivered', 'sent','enqueued'].include? params['payload']['type'] # Logs message status callbacks
      Rails.logger.info "GUPSHUP CALLBACK: App => #{params[:app]}, Timestamp => #{params[:timestamp]}, Status => #{params[:payload][:type]}"
    else # Incoming message events
      Rails.logger.info 'Gupshup event recieved'
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
      :payload => [:id, :source, :text, :type,:payload=>[:text, :url, :contentType, :caption], :sender => [:phone, :name]]
    )
  end
end
