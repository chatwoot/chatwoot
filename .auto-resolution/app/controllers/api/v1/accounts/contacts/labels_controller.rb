class Api::V1::Accounts::Contacts::LabelsController < Api::V1::Accounts::Contacts::BaseController
  include LabelConcern

  private

  def model
    @model ||= @contact
  end

  def permitted_params
    params.permit(labels: [])
  end
end
