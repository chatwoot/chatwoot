class Schedulers::DispatchService
  def initialize(account)
    @account = account
  end

  def perform
    due_messages.find_each(batch_size: 100) do |scheduled_message|
      dispatch(scheduled_message)
    end
  end

  private

  def due_messages
    @account.scheduled_messages
            .joins(:scheduler)
            .where(status: 'pending')
            .where('scheduled_messages.scheduled_at <= ?', Time.current)
            .where(schedulers: { status: :active })
            .includes(:scheduler, :contact, scheduler: :inbox)
            .order(:scheduled_at)
  end

  def dispatch(scheduled_message)
    contact = scheduled_message.contact
    scheduler = scheduled_message.scheduler

    if contact.blank? || contact.phone_number.blank?
      scheduled_message.mark_skipped!(reason: 'No matched contact or phone number')
      return
    end

    channel = scheduler.inbox.channel
    unless channel.is_a?(Channel::Whatsapp)
      scheduled_message.mark_failed!(error: 'Inbox is not a WhatsApp channel')
      return
    end

    template_params = Schedulers::MessageBuilderService.new(
      scheduler: scheduler,
      scheduled_message: scheduled_message
    ).build

    if template_params.blank?
      scheduled_message.mark_failed!(error: 'No template configured')
      return
    end

    send_template(channel, contact.phone_number, template_params, scheduled_message)
  rescue StandardError => e
    Rails.logger.error "Scheduler dispatch failed for message #{scheduled_message.id}: #{e.message}"
    scheduled_message.mark_failed!(error: e.message)
  end

  def send_template(channel, phone_number, template_params, scheduled_message)
    processor = Whatsapp::TemplateProcessorService.new(
      channel: channel,
      template_params: template_params
    )

    name, namespace, lang_code, processed_parameters = processor.call

    if name.blank?
      scheduled_message.mark_failed!(error: 'Template not found or not approved')
      return
    end

    response = channel.send_template(phone_number, {
                                       name: name,
                                       namespace: namespace,
                                       lang_code: lang_code,
                                       parameters: processed_parameters
                                     }, nil)

    scheduled_message.mark_sent!(whatsapp_message_id: response)
  end
end
