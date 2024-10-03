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

  def data_source_values
    data_sources_for_account = CustomAttributeDefinition.find_by(account_id: Current.account.id, attribute_model: :contact_attribute,
                                                                 attribute_key: 'data_source')&.attribute_values
    data_sources_for_account = Contact.pluck(:initial_channel_type).compact.uniq if data_sources_for_account.blank?
    render json: data_sources_for_account, status: :ok
  end

  private

  def fetch_custom_attributes_definitions
    @custom_attribute_definitions = Current.account.custom_attribute_definitions
                                           .with_attribute_model(permitted_params[:attribute_model])
                                           .order(id: :asc)
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
      :regex_cue,
      attribute_values: []
    )
  end

  def permitted_params
    params.permit(:id, :filter_type, :attribute_model)
  end
end
