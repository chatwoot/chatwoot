class Api::V1::Accounts::Captain::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant
  before_action :set_document, only: [:show, :destroy]

  def index
    @documents = @assistant.documents.ordered
  end

  def show; end

  def create
    @document = @assistant.documents.build(document_params)
    @document.save!
  end

  def destroy
    @document.destroy
    head :no_content
  end

  private

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end

  def set_document
    @document = @assistant.documents.find(params[:id])
  end

  def document_params
    params.require(:document).permit(:name, :external_link)
  end
end
