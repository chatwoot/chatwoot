class Digitaltolk::SendEmailTicketService
  include DateRangeHelper
  attr_accessor :account, :user, :params, :errors, :conversation, :for_issue

  CUSTOMER_TYPE = 2
  TRANSLATOR_TYPE = 3

  def initialize(account, user, params, for_issue: false)
    @account = account
    @user = user
    @params = params
    @errors = []
    @for_issue = for_issue
  end

  def perform
    begin
      ActiveRecord::Base.transaction do
        validate_params
        find_or_create_conversation
        validate_data
        create_message
        update_status
      end
    rescue StandardError => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.first
      @errors << e.message
    end

    result_data
  end

  private

  def result_data
    return result_json(true, 'Email sent!') if @errors.blank?

    result_json(false, @errors.join(', '))
  end

  def result_json(success, message)
    {
      success: success,
      message: message,
      conversation_id: @conversation&.display_id
    }
  end

  def conversations
    inbox.conversations
  end

  def conversation_params
    {
      subject: params[:title],
      content: params[:body],
      inbox_id: params[:inbox_id],
      email: params_email,
      assignee_id: nil,
      account_id: @account.id,
      team_id: params[:team_id]
    }
  end

  def find_or_create_conversation
    return if @errors.present?

    if find_contact_by_email
      if for_issue
        if booking_issue_id
          convos = conversations.where("custom_attributes ->> 'booking_id' = ?", booking_id)
                                .where("custom_attributes ->> 'booking_issue_id' = ?", booking_issue_id)
          convos = filter_conversation_by_email(convos)
          @conversation = convos.last
        end
      else
        convos = conversations.where("custom_attributes ->> 'booking_id' = ?", booking_id)
        convos = filter_conversation_by_email(convos)
        @conversation = convos.last
      end
    end

    return if @conversation.present?

    create_conversation
    assign_booking_id
    assign_booking_issue_id if for_issue
  end

  def filter_conversation_by_email(convos)
    convos = convos.where(contact_id: find_contact_by_email.id) if find_contact_by_email.present?

    convos
  end

  def params_email
    params.dig(:requester, :email).to_s
  end

  def find_contact_by_email
    @find_contact_by_email ||= @account.contacts.from_email(params_email)
  end

  def create_conversation
    @conversation = Digitaltolk::AddConversationService.new(inbox_id, conversation_params).perform
  end

  def assign_booking_id
    @conversation.custom_attributes['booking_id'] = booking_id
    @conversation.save
  end

  def assign_booking_issue_id
    @conversation.custom_attributes['booking_issue_id'] = booking_issue_id
    @conversation.save
  end

  def for_customer?
    recipient_type.to_i == CUSTOMER_TYPE
  end

  def for_translator?
    recipient_type.to_i == TRANSLATOR_TYPE
  end

  def recipient_type
    params[:recipient_type]
  end

  def inbox
    @inbox ||= @account.inboxes.find_by(id: inbox_id)
  end

  def inbox_id
    params[:inbox_id]
  end

  def booking_id
    params[:booking_id].to_s
  end

  def booking_issue_id
    params[:booking_issue_id].to_s
  end

  def validate_booking_id
    return if booking_id.present?

    @errors << 'Parameter booking_id is required'
  end

  def validate_recipient_type
    if recipient_type.blank?
      @errors << 'Recipient Type is required'
    elsif !for_customer? && !for_translator?
      @errors << "Unknown recipient_type #{recipient_type}"
    end
  end

  def validate_inbox
    return if inbox.present?

    @errors << "Inbox with id #{inbox_id} was not found"
  end

  def validate_booking_issue
    return unless for_issue
    return if booking_issue_id.present?

    @errors << 'Parameter booking_issue_id is required'
  end

  def validate_params
    validate_booking_id
    validate_recipient_type
    validate_inbox
    validate_booking_issue
  end

  def validate_data
    return if @errors.blank?

    @errors << invalid_booking_message if @conversation.blank?
  end

  def invalid_booking_message
    "Conversation with booking ID #{booking_id} not found"
  end

  def create_message
    return if @errors.present?

    @message = Digitaltolk::AddMessageService.new(sender, @conversation, @params[:body]).perform
  end

  def find_user_by_email
    User.from_email(created_by_email)
  end

  def created_by_email
    params.dig(:created_by, :email).to_s
  end

  def sender
    # find_user_by_email || @user
    @user
  end

  def update_status
    return if @errors.present?
    return unless valid_status?

    @conversation.status = params[:status]
    @conversation.snoozed_until = parse_date_time(params[:snoozed_until].to_s) if params[:snoozed_until]
    @conversation.save
  end

  def valid_status?
    [:open, :resolved, :pending, :snoozed].include?(params[:status].to_s.to_sym)
  end
end
