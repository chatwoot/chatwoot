class Api::V1::Accounts::CustomAttributeDefinitionsController < Api::V1::Accounts::BaseController
  before_action :fetch_custom_attributes_definitions, except: [:create]
  before_action :fetch_custom_attribute_definition, only: [:show, :update, :destroy]
  DEFAULT_ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

  def index; end

  def show; end

  def create
    @custom_attribute_definition = Current.account.custom_attribute_definitions.create!(
      permitted_payload
    )
  end

  def update
    @custom_attribute_definition.update!(permitted_payload)
  end

  def destroy
    @custom_attribute_definition.destroy!
    head :no_content
  end

  def update_by_key
    custom_attribute_definition_data = Current.account.custom_attribute_definitions
    Rails.logger.info("custom_attribute_definition_data, #{custom_attribute_definition_data.inspect}")

    custom_attribute_definition = custom_attribute_definition_data.find_by(attribute_key: params[:attribute_key])

    if custom_attribute_definition
      if custom_attribute_definition.update(attribute_values_params)
        render json: custom_attribute_definition, status: :ok
      else
        render json: { errors: custom_attribute_definition.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Custom attribute definition not found' }, status: :not_found
    end
  end

  private

  def fetch_custom_attributes_definitions
    @custom_attribute_definitions = Current.account.custom_attribute_definitions.with_attribute_model(permitted_params[:attribute_model])
  end

  def fetch_custom_attribute_definition
    @custom_attribute_definition = Current.account.custom_attribute_definitions.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:custom_attribute_definition).permit(
      :attribute_display_name,
      :attribute_description,
      :attribute_display_type,
      :attribute_key,
      :attribute_model,
      :regex_pattern,
      :required_before_resolve,
      :regex_cue,
      attribute_values: []
    )
  end

  def permitted_params
    params.permit(:id, :filter_type, :attribute_model)
  end

  def attribute_values_params
    params.require(:custom_attribute_definition).permit(attribute_values: [])
  end
end
