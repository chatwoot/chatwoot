class Api::V1::Accounts::MessageTemplatesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_message_template, only: [:show, :update, :destroy]

  def index
    @message_templates = Current.account.message_templates
    @message_templates = @message_templates.by_inbox(params[:inbox_id]) if params[:inbox_id].present?
    @message_templates = @message_templates.by_channel_type(params[:channel_type]) if params[:channel_type].present?
    @message_templates = @message_templates.by_status(params[:status]) if params[:status].present?
    @message_templates = @message_templates.order(updated_at: :desc)
  end

  def show; end

  def create
    @message_template = Current.account.message_templates.new(message_template_params)
    @message_template.created_by = Current.user
    @message_template.updated_by = Current.user
    @message_template.save!

    # If an inbox is attached, submit to Meta immediately
    if @message_template.inbox.present? && @message_template.status_draft?
      inbox = @message_template.inbox
      result = Whatsapp::TemplateCreationService.new(message_template: @message_template, inbox: inbox).perform
      unless result[:success]
        @message_template.destroy!
        return render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    render :show, status: :created
  end

  def update
    @message_template.update!(message_template_params)
    @message_template.update!(updated_by: Current.user)

    # Re-submit to Meta if template is tied to an inbox and still editable
    if @message_template.inbox.present? && @message_template.status_draft?
      inbox = @message_template.inbox
      result = Whatsapp::TemplateCreationService.new(message_template: @message_template, inbox: inbox).perform
      return render json: { error: result[:error] }, status: :unprocessable_entity unless result[:success]
    end

    render :show
  end

  def destroy
    @message_template.destroy!
    head :ok
  end

  def sync
    inbox = Current.account.inboxes.find(params[:inbox_id])
    Whatsapp::TemplateSyncService.new(inbox: inbox).perform
    @message_templates = Current.account.message_templates.by_inbox(inbox.id).order(updated_at: :desc)
    render :index
  end

  private

  def fetch_message_template
    @message_template = Current.account.message_templates.find(params[:id])
  end

  def message_template_params
    params.require(:message_template).permit(
      :name, :language, :channel_type, :category, :inbox_id,
      content: {},
      metadata: {}
    )
  end
end
