class Fonnte::CallbackController < ApplicationController
  # include MetaTokenVerifyConcern
  # skip_before_action :verify_authenticity_token
  # before_action :verify_meta_token

  def index
    head :ok
  end

  def create
    Rails.logger.info "Fonnte callback params: #{permitted_params.inspect}"
    Fonnte::IncomingMessageService.new(params: permitted_params).perform
    head :ok
  end

  private

  def permitted_params # rubocop:disable Metrics/MethodLength
    params.permit(
      :quick,
      :device,
      :pesan,
      :pengirim,
      :member,
      :message,
      :text,
      :sender,
      :name,
      :location,
      :url,
      :type,
      :extension,
      :filename,
      :pollname,
      :inboxid,
      :isgroup,
      :isforwarded
    )
  end
end
