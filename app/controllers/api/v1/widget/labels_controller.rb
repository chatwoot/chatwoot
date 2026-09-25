class Api::V1::Widget::LabelsController < Api::V1::Widget::BaseController
  def create
    conversation.add_labels(permitted_params[:label]) if conversation.present? && label_defined_in_account?

    head :no_content
  end

  def destroy
    conversation.update!(label_list: conversation.label_list - [permitted_params[:id]]) if conversation.present?

    head :no_content
  end

  private

  def label_defined_in_account?
    label = @current_account.labels&.find_by(title: permitted_params[:label])
    label.present?
  end

  def permitted_params
    params.permit(:id, :label, :website_token)
  end
end
