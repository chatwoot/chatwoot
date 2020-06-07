class Api::V1::Accounts::LabelsController < Api::BaseController
  before_action :current_account
  before_action :fetch_label, except: [:index, :create]
  before_action :check_authorization

  def index
    @labels = policy_scope(current_account.labels)
  end

  def show; end

  def create
    @label = current_account.labels.create!(permitted_params)
  end

  def update
    @label.update(permitted_params)
  end

  def destroy
    @label.destroy
    head :ok
  end

  private

  def fetch_label
    @label = current_account.labels.find(params[:id])
  end

  def check_authorization
    authorize(Label)
  end

  def permitted_params
    params.require(:label).permit(:title, :description, :color, :show_on_sidebar)
  end
end
