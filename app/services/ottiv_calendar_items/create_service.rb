class OttivCalendarItems::CreateService
  attr_reader :params, :user, :account

  def initialize(params:, user:, account:)
    @params = params
    @user = user
    @account = account
  end

  def perform
    ActiveRecord::Base.transaction do
      calendar_item = create_calendar_item
      create_contacts(calendar_item) if params[:contact_ids].present?
      create_participants(calendar_item) # Sempre cria, incluindo o criador
      create_reminders(calendar_item) if params[:reminders].present?

      # Notificar participantes após criação
      OttivNotifyParticipantsJob.perform_later(calendar_item.id)

      calendar_item
    end
  end

  private

  def create_calendar_item
    calendar_item = OttivCalendarItem.new(calendar_item_params)
    calendar_item.user = user
    calendar_item.account = account
    calendar_item.save!
    calendar_item
  end

  def create_contacts(calendar_item)
    return unless params[:contact_ids].is_a?(Array)

    params[:contact_ids].each do |contact_id|
      calendar_item.ottiv_calendar_item_contacts.create!(contact_id: contact_id)
    end
  end

  def create_participants(calendar_item)
    participant_ids = params[:participant_ids] || []
    participant_ids = participant_ids.to_a if participant_ids.respond_to?(:to_a)

    # Sempre adicionar o criador como participante
    # Isso garante que o criador sempre será notificado
    participant_ids = (participant_ids + [calendar_item.user_id]).uniq

    participant_ids.each do |user_id|
      calendar_item.ottiv_calendar_item_participants.create!(user_id: user_id)
    end
  end

  def create_reminders(calendar_item)
    return unless params[:reminders].is_a?(Array)

    params[:reminders].each do |reminder_data|
      calendar_item.ottiv_reminders.create!(
        notify_at: reminder_data[:notify_at],
        channel: reminder_data[:channel] || 'in_app'
      )
    end
  end

  def calendar_item_params
    params.permit(
      :item_type,
      :title,
      :description,
      :start_at,
      :end_at,
      :location,
      :status,
      :conversation_id
    )
  end
end

