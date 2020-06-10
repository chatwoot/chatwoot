class Api::V1::Accounts::Conversations::LabelsController < Api::V1::Accounts::Conversations::BaseController
  def create
    @conversation.update_labels(params[:labels])
    @labels = @conversation.label_list
  end

  # all labels of the current conversation
  def index
    @labels = @conversation.label_list
  end
end
