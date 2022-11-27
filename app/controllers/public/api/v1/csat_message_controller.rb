class Public::Api::V1::CsatMessageController < PublicController
  before_action :get_message

  private

  def get_message
    return if params[:id].blank?

    begin
      @conversation = Conversation.find_by!(uuid: params[:id])
      @inbox = Inbox.find(@conversation.inbox_id)
      render json: {
        csat_message: @inbox.csat_message
      }      
    rescue => e
      render json: {
        csat_message: ""
      }      
    end
  end
end
