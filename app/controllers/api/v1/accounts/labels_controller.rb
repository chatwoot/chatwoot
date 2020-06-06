class Api::V1::Accounts::LabelsController < Api::V1::Accounts::BaseController
  # list all labels in account
  def index
    @labels = Current.account.all_conversation_tags
  end

  def most_used
    @labels = ActsAsTaggableOn::Tag.most_used(params[:count] || 10)
  end
end
