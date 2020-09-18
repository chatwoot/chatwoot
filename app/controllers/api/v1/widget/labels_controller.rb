class Api::V1::Widget::LabelsController < Api::V1::Widget::BaseController
  def create
    if conversation.present?
      conversation.label_list.add(permitted_params[:label])
      conversation.save!
    end

    head :no_content
  end

  def destroy
    if conversation.present?
      conversation.label_list.remove(permitted_params[:id])
      conversation.save!
    end

    head :no_content
  end

  private

  def permitted_params
    params.permit(:id, :label, :website_token)
  end
end
