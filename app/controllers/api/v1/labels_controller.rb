class Api::V1::LabelsController < Api::BaseController
  def index # list all labels in account
    @labels = current_account.all_conversation_tags
  end
end
