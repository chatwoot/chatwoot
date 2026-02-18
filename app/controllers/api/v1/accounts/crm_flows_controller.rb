class Api::V1::Accounts::CrmFlowsController < Api::V1::Accounts::BaseController
  before_action :set_crm_flow, only: %i[show update destroy executions]

  # GET /api/v1/accounts/:account_id/crm_flows
  def index
    flows = CrmFlow.where(account_id: Current.account.id).order(created_at: :desc)
    render json: { flows: flows.map { |f| serialize_full(f) } }
  end

  # GET /api/v1/accounts/:account_id/crm_flows/:id
  def show
    render json: serialize_full(@crm_flow)
  end

  # POST /api/v1/accounts/:account_id/crm_flows
  def create
    flow = CrmFlow.new(crm_flow_params.merge(account_id: Current.account.id))
    if flow.save
      render json: serialize_full(flow), status: :created
    else
      render json: { errors: flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/crm_flows/:id
  def update
    if @crm_flow.update(crm_flow_params)
      render json: serialize_full(@crm_flow)
    else
      render json: { errors: @crm_flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/crm_flows/:id
  def destroy
    @crm_flow.destroy!
    head :no_content
  end

  # POST /api/v1/accounts/:account_id/crm_flows/trigger
  def trigger
    idempotency_key = request.headers['Idempotency-Key']
    unless idempotency_key
      return render json: { error: 'Idempotency-Key header is required' }, status: :bad_request
    end

    result = CrmFlows::TriggerService.new(
      account:        Current.account,
      trigger_type:   params[:trigger_type],
      conversation_id: params[:conversation_id],
      contact_id:     params[:contact_id],
      metadata:       params[:metadata]&.to_unsafe_h || {},
      idempotency_key: idempotency_key
    ).call

    render_trigger_result(result)
  end

  # GET /api/v1/accounts/:account_id/crm_flows/trigger_schema
  def trigger_schema
    flow = CrmFlow.resolve_for(
      account_id: Current.account.id,
      trigger_type: params[:trigger_type],
      inbox_id:    params[:inbox_id]
    )
    return render json: { error: 'No flow encontrado' }, status: :not_found unless flow

    render json: CrmFlows::SchemaService.new(flow).schema
  end

  # GET /api/v1/accounts/:account_id/crm_flows/agent_schema
  # Params: trigger_type (required), contact_id or conversation_id (required), inbox_id (optional)
  # Returns active flows for the trigger with per-action metadata requirements,
  # auto-filled contact fields, and the list of missing fields the agent must collect.
  def agent_schema
    trigger_type = params[:trigger_type]
    return render json: { error: 'trigger_type is required' }, status: :bad_request unless trigger_type

    contact = resolve_agent_contact
    return render json: { error: 'Contact not found' }, status: :not_found unless contact

    result = CrmFlows::AgentSchemaService.new(
      account: Current.account,
      trigger_type: trigger_type,
      contact: contact,
      inbox_id: params[:inbox_id]
    ).call

    render json: result
  end

  # GET /api/v1/accounts/:account_id/crm_flows/:id/executions
  def executions
    execs = @crm_flow.crm_flow_executions.order(created_at: :desc).limit(50)
    render json: { executions: execs.map { |e| serialize_execution(e) } }
  end

  # GET /api/v1/accounts/:account_id/crm_flows/executions_by_conversation
  def executions_by_conversation
    execs = CrmFlowExecution.joins(:crm_flow)
      .where(crm_flows: { account_id: Current.account.id })
      .where(conversation_id: params[:conversation_id])
      .order(created_at: :desc)
      .limit(20)
    render json: { executions: execs.map { |e| serialize_execution(e) } }
  end

  private

  def set_crm_flow
    @crm_flow = CrmFlow.where(account_id: Current.account.id).find(params[:id])
  end

  def resolve_agent_contact
    if params[:contact_id]
      Contact.find_by(id: params[:contact_id], account_id: Current.account.id)
    elsif params[:conversation_id]
      Conversation.find_by(id: params[:conversation_id], account_id: Current.account.id)&.contact
    end
  end

  def crm_flow_params
    params.require(:crm_flow).permit(
      :name, :trigger_type, :scope_type, :inbox_id, :active, :dedup_window_minutes,
      actions: [:order, :action, :type, { params: [:tag_name, :agent_id, :label, :subject, :note_title, :note_text, :description] }],
      required_fields: [:key, :label, :type, :required, { options: [] }]
    )
  end

  def serialize_list_item(flow)
    {
      id:             flow.id,
      name:           flow.name,
      trigger_type:   flow.trigger_type,
      scope_type:     flow.scope_type,
      inbox_id:       flow.inbox_id,
      inbox_name:     flow.inbox&.name,
      actions_count:  (flow.actions || []).length,
      active:         flow.active,
      created_at:     flow.created_at
    }
  end

  def serialize_full(flow)
    serialize_list_item(flow).merge(
      actions:              flow.actions,
      required_fields:      flow.required_fields,
      dedup_window_minutes: flow.dedup_window_minutes
    )
  end

  def serialize_execution(exec)
    {
      id:              exec.id,
      flow_id:         exec.crm_flow_id,
      flow_name:       exec.crm_flow&.name,
      conversation_id: exec.conversation_id,
      contact:         exec.contact ? { id: exec.contact.id, name: exec.contact.name } : nil,
      status:          exec.status,
      results:         exec.results,
      created_at:      exec.created_at
    }
  end

  def render_trigger_result(result)
    case result[:status]
    when :queued
      render json: { status: 'queued', flow_id: result[:flow_id], flow_name: result[:flow_name] }, status: :accepted
    when :processing
      render json: { status: 'processing' }, status: :conflict
    when :completed
      render json: { status: 'completed', result: result[:result] }
    when :failed
      render json: { status: 'failed', error: result[:error] }
    when :deduplicated
      render json: { status: 'deduplicated' }
    when :not_found
      render json: { error: result[:error] }, status: :not_found
    when :validation_failed
      render json: { error: 'missing_required_fields', missing_fields: result[:missing_fields] }, status: :unprocessable_entity
    end
  end
end
