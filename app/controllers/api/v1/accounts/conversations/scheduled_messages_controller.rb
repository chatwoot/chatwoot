class Api::V1::Accounts::Conversations::ScheduledMessagesController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  before_action :scheduled_message, only: [:update, :destroy]

  MAX_LIMIT = 100

  def index
    authorize build_scheduled_message
    @scheduled_messages = @conversation.scheduled_messages
                                       .includes(:recurring_scheduled_message)
                                       .order(scheduled_at: :desc)
                                       .limit(MAX_LIMIT)
  end

  def create
    @scheduled_message = build_scheduled_message
    authorize @scheduled_message
    @scheduled_message.assign_attributes(scheduled_message_params)
    @scheduled_message.save!
    dispatch_event(SCHEDULED_MESSAGE_CREATED, scheduled_message: @scheduled_message)
  end

  def update
    @scheduled_message.assign_attributes(scheduled_message_params)
    @scheduled_message.attachment.purge if params[:remove_attachment].present? && @scheduled_message.attachment.attached?
    @scheduled_message.save!
    dispatch_event(SCHEDULED_MESSAGE_UPDATED, scheduled_message: @scheduled_message)
  end

  def destroy
    if @scheduled_message.sent? || @scheduled_message.failed?
      return render json: { error: I18n.t('errors.scheduled_messages.cannot_delete_processed') }, status: :unprocessable_entity
    end

    scheduled_message = @scheduled_message
    scheduled_message.destroy!
    dispatch_event(SCHEDULED_MESSAGE_DELETED, scheduled_message: scheduled_message)
  end

  private

  def scheduled_message
    @scheduled_message ||= @conversation.scheduled_messages.find(params[:id])
    authorize @scheduled_message
  end

  def build_scheduled_message
    @conversation.scheduled_messages.new(account: Current.account, inbox: @conversation.inbox, author: Current.user)
  end

  def scheduled_message_params
    params.permit(
      :content,
      :scheduled_at,
      :status,
      :attachment,
      template_params: {}
    )
  end

  def dispatch_event(event_name, data)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, data)
  end
end

Api::V1::Accounts::Conversations::ScheduledMessagesController.prepend_mod_with(
  'Api::V1::Accounts::Conversations::ScheduledMessagesController'
)
