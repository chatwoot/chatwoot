class Api::V1::Accounts::CustomAttributeDefinitionsController < Api::V1::Accounts::BaseController
  before_action :fetch_custom_attributes_definitions, except: [:create]
  before_action :fetch_custom_attribute_definition, only: [:show, :update, :destroy, :recalculate, :preview]
  before_action :check_authorization
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

  # POST /api/v1/accounts/:account_id/custom_attribute_definitions/:id/recalculate
  # Manually enqueues a recompute for this formula definition.
  def recalculate
    unless @custom_attribute_definition.formula?
      render json: { error: 'Definition has no formula' }, status: :unprocessable_entity
      return
    end

    enqueue_recompute_for(@custom_attribute_definition)
    render json: { status: 'queued' }, status: :accepted
  end

  # POST /api/v1/accounts/:account_id/custom_attribute_definitions/:id/preview
  # Body: { sample_attributes: { "key" => value } }
  # Returns the computed value for the provided sample without persisting it.
  def preview
    unless @custom_attribute_definition.formula?
      render json: { error: 'Definition has no formula' }, status: :unprocessable_entity
      return
    end

    sample = params.permit(sample_attributes: {}).to_h[:sample_attributes] || {}
    sample = sample.transform_keys(&:to_s)
    value = FormulaPreviewService.new(@custom_attribute_definition, sample).compute
    render json: { value: value }
  end

  private

  def enqueue_recompute_for(definition)
    case definition.attribute_model
    when 'contact_attribute'
      CustomAttributes::RecomputeAccountContactFormulasJob.perform_later(definition.account_id)
    when 'conversation_attribute'
      CustomAttributes::RecomputeAccountConversationFormulasJob.perform_later(definition.account_id)
    when 'company_attribute'
      CustomAttributes::RecomputeAccountCompanyFormulasJob.perform_later(definition.account_id)
    end
  end

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
      :regex_cue,
      :featured,
      :category,
      attribute_values: [],
      formula: [:op, :source_attribute_key, :source_model]
    )
  end

  def permitted_params
    params.permit(:id, :filter_type, :attribute_model)
  end
end
