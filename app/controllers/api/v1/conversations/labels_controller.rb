class Api::V1::Conversations::LabelsController < Api::BaseController
  before_action :set_conversation, only: [:create, :index]

  def create
    @conversation.update_labels(params[:labels])
    @labels = @conversation.label_list
  end

  def index # all labels of the current conversation
    @labels = @conversation.label_list
  end
end
