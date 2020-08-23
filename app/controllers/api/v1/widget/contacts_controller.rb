class Api::V1::Widget::ContactsController < Api::V1::Widget::BaseController
  def update
    contact_identify_action = ContactIdentifyAction.new(
      contact: @contact,
      params: permitted_params.to_h.deep_symbolize_keys
    )
    render json: contact_identify_action.perform
  end

  private

  def permitted_params
    params.permit(:website_token, :identifier, :email, :name, :avatar_url, custom_attributes: {})
  end
end
