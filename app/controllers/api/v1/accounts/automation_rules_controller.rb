class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  include AttachmentConcern

  before_action :check_authorization
  before_action :fetch_automation_rule, only: [:show, :update, :destroy, :clone]
  before_action :ensure_execution_delay_allowed, only: [:create, :update]

  def index
    @automation_rules = Current.account.automation_rules
  end

  def show; end

  def create
    blobs, actions, error = validate_and_prepare_attachments(params[:actions])
    return render_could_not_create_error(error) if error

    @automation_rule = Current.account.automation_rules.new(automation_rules_permit)
    @automation_rule.actions = actions
    @automation_rule.conditions = params[:conditions]

    return render_could_not_create_error(@automation_rule.errors.messages) unless @automation_rule.valid?

    @automation_rule.save!
    blobs.each { |blob| @automation_rule.files.attach(blob) }
  end

  def update
    blobs, actions, error = validate_and_prepare_attachments(params[:actions], @automation_rule)
    return render_could_not_create_error(error) if error

    ActiveRecord::Base.transaction do
      @automation_rule.assign_attributes(automation_rules_permit)
      @automation_rule.actions = actions if params[:actions]
      @automation_rule.conditions = params[:conditions] if params[:conditions]
      @automation_rule.save!
      blobs.each { |blob| @automation_rule.files.attach(blob) }
    rescue StandardError => e
      Rails.logger.error e
      render_could_not_create_error(@automation_rule.errors.messages)
    end
  end

  def destroy
    @automation_rule.destroy!
    head :ok
  end

  def clone
    automation_rule = Current.account.automation_rules.find_by(id: params[:automation_rule_id])
    new_rule = automation_rule.dup
    # dup copies execution_delay; drop it when the feature is off so clone can't create new
    # delayed rules that create/update would reject.
    new_rule.execution_delay = nil unless delayed_automations_enabled?
    new_rule.save!
    @automation_rule = new_rule
  end

  private

  def automation_rules_permit
    permitted_attributes = [:name, :description, :event_name, :active]
    permitted_attributes << :execution_delay if delayed_automations_enabled?

    params.permit(
      *permitted_attributes,
      conditions: [:attribute_key, :filter_operator, :query_operator, :custom_attribute_type, { values: [] }],
      actions: [:action_name, { action_params: [] }]
    )
  end

  def ensure_execution_delay_allowed
    return if delayed_automations_enabled?
    return if params[:execution_delay].blank?

    render json: { error: 'Delayed automations are not enabled for this account.' }, status: :unprocessable_entity
  end

  def delayed_automations_enabled?
    Current.account.feature_enabled?('delayed_automations')
  end

  def fetch_automation_rule
    @automation_rule = Current.account.automation_rules.find_by(id: params[:id])
  end
end
