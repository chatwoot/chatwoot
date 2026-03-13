class Api::V1::Accounts::ConversationClassificationsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_classification, except: [:index, :create]
  before_action :check_authorization

  def index
    @classifications = Current.account.conversation_classifications
  end

  def create
    @classification = Current.account.conversation_classifications.create!(permitted_params)
  end

  def update
    @classification.update!(permitted_params)
  end

  def destroy
    @classification.destroy!
    head :ok
  end

  private

  def fetch_classification
    @classification = Current.account.conversation_classifications.find(params[:id])
  end

  def permitted_params
    params.require(:conversation_classification).permit(:name, :position)
  end
end
