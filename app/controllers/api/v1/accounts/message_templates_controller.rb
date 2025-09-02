class Api::V1::Accounts::MessageTemplatesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_message_template, only: [:show, :update, :destroy]

  def index
    @message_templates = message_templates_scope
  end

  def show; end

  def create
    @message_template = Current.account.message_templates.new(message_template_params)
    @message_template.created_by = Current.user
    @message_template.save!
  rescue ActiveRecord::RecordNotSaved
    render json: { error: @message_template.errors.full_messages.join(', ') }, status: :unprocessable_entity
  end

  def update
    @message_template.update!(message_template_params)
    @message_template.updated_by = Current.user
    @message_template.save!
  end

  def destroy
    @message_template.destroy!
    head :ok
  end

  private

  def fetch_message_template
    @message_template = Current.account.message_templates.find(params[:id])
  end

  def message_template_params
    params.require(:message_template).permit(
      :name, :category, :language, :channel_type, :status,
      :inbox_id, :platform_template_id,
      content: {}, metadata: {}
    )
  end

  def message_templates_scope
    scope = Current.account.message_templates
    scope = scope.by_inbox(params[:inbox_id]) if params[:inbox_id]
    scope = scope.by_channel_type(params[:channel_type]) if params[:channel_type]
    scope = scope.by_language(params[:language]) if params[:language]
    scope = scope.approved if params[:approved_only]
    scope
  end
end
