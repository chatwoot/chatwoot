class Public::Api::V1::InboxesController < PublicController
  before_action :set_inbox_channel

  private

  def set_inbox_channel
    @inbox_channel = ::Channel::Api.find_by!(identifier: params[:inbox_id])
  end
end
