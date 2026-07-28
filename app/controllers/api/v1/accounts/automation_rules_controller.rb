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
    # Dropping the delay here would clone a paused wait into a rule that fires instantly on the
    # next matching event, so refuse rather than rewrite what the rule means.
    return render_delayed_automations_error if automation_rule.execution_delay.present? && !delayed_automations_enabled?

    @automation_rule = automation_rule.dup
    @automation_rule.save!
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

    render_delayed_automations_error
  end

  def render_delayed_automations_error
    render json: { error: 'Delayed automations are not enabled for this account.' }, status: :unprocessable_entity
  end

  def delayed_automations_enabled?
    Current.account.feature_enabled?('delayed_automations')
  end

  def fetch_automation_rule
    @automation_rule = Current.account.automation_rules.find_by(id: params[:id])
  end
end
