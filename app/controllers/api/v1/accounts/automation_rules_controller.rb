class Api::V1::Accounts::AutomationRulesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_automation_rule, only: [:show, :update, :destroy, :clone]

  def index
    @automation_rules = Current.account.automation_rules
  end

  def show; end

  def create
    @automation_rule = Current.account.automation_rules.new(automation_rules_permit)
    @automation_rule.actions = params[:actions]
    @automation_rule.conditions = params[:conditions]

    render json: { error: @automation_rule.errors.messages }, status: :unprocessable_entity and return unless @automation_rule.valid?

    @automation_rule.save!
    process_attachments
    @automation_rule
  end

  def update
    ActiveRecord::Base.transaction do
      automation_rule_update
      process_attachments
    rescue StandardError => e
      Rails.logger.error e
      render json: { error: @automation_rule.errors.messages }.to_json, status: :unprocessable_entity
    end
  end

  def destroy
    @automation_rule.destroy!
    head :ok
  end

  def clone
    automation_rule = Current.account.automation_rules.find_by(id: params[:automation_rule_id])
    new_rule = automation_rule.dup
    new_rule.save!
    @automation_rule = new_rule
  end

  def process_attachments
    actions = @automation_rule.actions.filter_map { |k, _v| k if k['action_name'] == 'send_attachment' }
    return if actions.blank?

    actions.each do |action|
      blob_id = action['action_params']
      blob = ActiveStorage::Blob.find_by(id: blob_id)
      @automation_rule.files.attach(blob)
    end
  end

  private

  def automation_rule_update
    @automation_rule.update!(automation_rules_permit)
    @automation_rule.actions = params[:actions] if params[:actions]
    @automation_rule.conditions = params[:conditions] if params[:conditions]
    @automation_rule.save!
  end

  def automation_rules_permit
    params.permit(
      :name, :description, :event_name, :account_id, :active,
      conditions: [:attribute_key, :filter_operator, :query_operator, :custom_attribute_type, { values: [] }],
      actions: [:action_name, { action_params: [] }]
    )
  end

  def fetch_automation_rule
    @automation_rule = Current.account.automation_rules.find_by(id: params[:id])
  end
end
