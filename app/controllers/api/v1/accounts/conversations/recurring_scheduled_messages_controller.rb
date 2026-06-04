class Api::V1::Accounts::Conversations::RecurringScheduledMessagesController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  before_action :set_recurring_scheduled_message, only: [:update, :destroy]

  MAX_LIMIT = 50

  def index
    authorize build_recurring_scheduled_message
    @recurring_scheduled_messages = @conversation.recurring_scheduled_messages
                                                 .includes(:scheduled_messages, :author)
                                                 .order(Arel.sql('CASE status WHEN 1 THEN 0 WHEN 0 THEN 1 ELSE 2 END, created_at DESC'))
                                                 .limit(MAX_LIMIT)
  end

  def create
    @recurring_scheduled_message = build_recurring_scheduled_message
    authorize @recurring_scheduled_message
    @recurring_scheduled_message.assign_attributes(recurring_scheduled_message_params)

    ActiveRecord::Base.transaction do
      @recurring_scheduled_message.save!
      create_first_occurrence if @recurring_scheduled_message.active?
    end

    dispatch_event(RECURRING_SCHEDULED_MESSAGE_CREATED)
  end

  def update
    @recurring_scheduled_message.assign_attributes(recurring_scheduled_message_params)

    ActiveRecord::Base.transaction do
      @recurring_scheduled_message.save!
      @recurring_scheduled_message.attachment.purge if params[:remove_attachment].present? && @recurring_scheduled_message.attachment.attached?

      if @recurring_scheduled_message.active?
        reschedule_pending_occurrence
      else
        @recurring_scheduled_message.scheduled_messages.pending.destroy_all
      end
    end

    dispatch_event(RECURRING_SCHEDULED_MESSAGE_UPDATED)
  end

  def destroy
    cancel_recurring_message
    dispatch_event(RECURRING_SCHEDULED_MESSAGE_UPDATED)
  end

  private

  def set_recurring_scheduled_message
    @recurring_scheduled_message = @conversation.recurring_scheduled_messages.find(params[:id])
    authorize @recurring_scheduled_message
  end

  def build_recurring_scheduled_message
    @conversation.recurring_scheduled_messages.new(account: Current.account, inbox: @conversation.inbox, author: Current.user)
  end

  def recurring_scheduled_message_params
    permitted = params.permit(
      :content,
      :status,
      :attachment,
      template_params: {},
      recurrence_rule: [:frequency, :interval, :end_type, :end_date, :end_count,
                        :monthly_type, :monthly_week, :monthly_weekday, :month_day,
                        :year_day, :year_month, { week_days: [] }]
    )

    permitted[:recurrence_rule] = cast_recurrence_rule(permitted[:recurrence_rule].to_h) if permitted[:recurrence_rule].present?

    permitted
  end

  def cast_recurrence_rule(rule)
    integer_keys = %w[interval end_count monthly_week monthly_weekday month_day year_day year_month]
    rule.each_with_object({}) do |(key, value), hash|
      hash[key] = if key == 'week_days' && value.is_a?(Array)
                    value.map(&:to_i)
                  elsif integer_keys.include?(key)
                    value.to_i
                  else
                    value
                  end
    end
  end

  def create_first_occurrence
    scheduled_at = params[:scheduled_at]
    return if scheduled_at.blank?

    sm = @recurring_scheduled_message.scheduled_messages.create!(
      content: @recurring_scheduled_message.content,
      template_params: @recurring_scheduled_message.template_params,
      scheduled_at: scheduled_at,
      status: :pending,
      account: @recurring_scheduled_message.account,
      conversation: @recurring_scheduled_message.conversation,
      inbox: @recurring_scheduled_message.inbox,
      author: @recurring_scheduled_message.author
    )
    copy_attachment(sm) if @recurring_scheduled_message.attachment.attached?
  end

  def reschedule_pending_occurrence
    @recurring_scheduled_message.scheduled_messages.pending.destroy_all

    next_scheduled_at = compute_next_valid_date
    return if next_scheduled_at.blank?

    sm = @recurring_scheduled_message.scheduled_messages.create!(
      content: @recurring_scheduled_message.content,
      template_params: @recurring_scheduled_message.template_params,
      scheduled_at: next_scheduled_at,
      status: :pending,
      account: @recurring_scheduled_message.account,
      conversation: @recurring_scheduled_message.conversation,
      inbox: @recurring_scheduled_message.inbox,
      author: @recurring_scheduled_message.author
    )
    copy_attachment(sm) if @recurring_scheduled_message.attachment.attached?
  end

  def compute_next_valid_date
    user_date = params[:scheduled_at].present? ? Time.zone.parse(params[:scheduled_at].to_s) : nil
    rule = @recurring_scheduled_message.recurrence_rule

    return user_date if user_date.present? && date_matches_rule?(user_date, rule)

    base = [user_date, Time.current].compact.max
    RecurringScheduledMessages::RecurrenceCalculatorService
      .new(recurrence_rule: rule, last_date: base)
      .next_date
  end

  def date_matches_rule?(date, rule)
    return true unless rule.is_a?(Hash)

    rule = rule.with_indifferent_access
    return true unless rule[:frequency] == 'weekly' && rule[:week_days].present?

    rule[:week_days].map(&:to_i).include?(date.wday)
  end

  def cancel_recurring_message
    @recurring_scheduled_message.scheduled_messages.pending.destroy_all
    @recurring_scheduled_message.update!(status: :cancelled)

    I18n.with_locale(@recurring_scheduled_message.account.locale) do
      @recurring_scheduled_message.conversation.messages.create!(
        account: @recurring_scheduled_message.account,
        inbox: @recurring_scheduled_message.inbox,
        message_type: :activity,
        content: I18n.t(
          'conversations.activity.recurring_message_cancelled',
          agent: @recurring_scheduled_message.author&.name || I18n.t('conversations.activity.unknown_agent')
        )
      )
    end
  end

  def copy_attachment(scheduled_message)
    scheduled_message.attachment.attach(@recurring_scheduled_message.attachment.blob)
  end

  def dispatch_event(event_name)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, recurring_scheduled_message: @recurring_scheduled_message)
  end
end

Api::V1::Accounts::Conversations::RecurringScheduledMessagesController.prepend_mod_with(
  'Api::V1::Accounts::Conversations::RecurringScheduledMessagesController'
)
