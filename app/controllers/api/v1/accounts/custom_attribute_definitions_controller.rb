class Api::V1::Accounts::CustomAttributeDefinitionsController < Api::V1::Accounts::BaseController
  before_action :fetch_custom_attributes_definitions, except: [:create, :reorder]
  before_action :fetch_custom_attribute_definition, only: [:show, :update, :destroy]
  before_action :check_authorization
  before_action :validate_reorder_positions, only: [:reorder]
  DEFAULT_ATTRIBUTE_MODEL = 'conversation_attribute'.freeze
  DEFINITION_ID_FORMAT = /\A\d+\z/
  MAX_REORDER_POSITION = 1_000_000

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

  def reorder
    CustomAttributeDefinition.update_positions(account: Current.account, positions_hash: reorder_positions)
    head :ok
  end

  private

  def fetch_custom_attributes_definitions
    @custom_attribute_definitions = Current.account.custom_attribute_definitions
                                           .with_attribute_model(permitted_params[:attribute_model])
                                           .order(:position, :id)
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

  def reorder_positions
    params.permit(positions_hash: {}).fetch(:positions_hash, {}).to_h
  end

  def validate_reorder_positions
    return if valid_reorder_positions?(reorder_positions)

    render json: { error: I18n.t('errors.custom_attribute_definition.invalid_positions') }, status: :unprocessable_entity
  end

  def valid_reorder_positions?(positions_hash)
    ids = positions_hash.keys
    positions = positions_hash.values
    return false if positions_hash.blank?
    return false unless ids.all? { |id| id.match?(DEFINITION_ID_FORMAT) }
    return false unless positions.all? { |position| position.is_a?(Integer) && position.between?(1, MAX_REORDER_POSITION) }

    positions.uniq.size == positions.size
  end

  def permitted_params
    params.permit(:id, :filter_type, :attribute_model)
  end
end
