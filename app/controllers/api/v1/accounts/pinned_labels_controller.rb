class Api::V1::Accounts::PinnedLabelsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_label

  def create
    current_user.pin_label(@label)
    head :ok
  end

  def destroy
    current_user.unpin_label(@label)
    head :ok
  end

  private

  def fetch_label
    @label = Current.account.labels.find(params[:label_id])
  end
end
