class Api::V1::Accounts::Contacts::LabelsController < Api::V1::Accounts::BaseController
  include LabelConcern

  private

  def model
    @model ||= Current.account.contacts.find(params[:contact_id])
  end

  def permitted_params
    params.permit(:contact_id, :labels)
  end
end
