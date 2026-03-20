class Api::V1::Accounts::Contacts::GroupMembersController < Api::V1::Accounts::Contacts::BaseController
  DEFAULT_PER_PAGE = 10

  before_action :ensure_group_contact, only: %i[create update destroy]

  def index
    authorize @contact, :show?

    base_query = GroupMember.active
                            .where(group_contact: @contact)
                            .includes(:contact)

    @total_count = base_query.count
    @page = [(params[:page] || 1).to_i, 1].max
    @per_page = (params[:per_page] || DEFAULT_PER_PAGE).to_i.clamp(1, 100)
    @inbox_phone_number = inbox_phone_number
    @is_inbox_admin = inbox_admin?

    paginated = base_query.order(role: :desc, id: :asc)
                          .offset((@page - 1) * @per_page)
                          .limit(@per_page)

    @group_members = pin_own_member_on_first_page(paginated)
  end

  def create
    authorize @contact, :update?
    participants = create_params[:participants]
    return render json: { error: 'participants_required' }, status: :unprocessable_entity if participants.blank?

    channel.update_group_participants(@contact.identifier, format_participants(participants), 'add')
    add_group_members(participants)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    authorize @contact, :update?
    role = update_params[:role]
    return render json: { error: 'invalid_role' }, status: :unprocessable_entity unless %w[admin member].include?(role)

    member = group_members.find(params[:member_id])
    action = role == 'admin' ? 'promote' : 'demote'
    channel.update_group_participants(@contact.identifier, [jid_for_member(member)], action)
    member.update!(role: role)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::GroupParticipantNotAllowedError
    render json: { error: 'group_creator_not_modifiable' }, status: :unprocessable_entity
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    authorize @contact, :update?

    member = group_members.find(params[:id])
    channel.update_group_participants(@contact.identifier, [jid_for_member(member)], 'remove')
    member.update!(is_active: false)
    head :ok
  rescue Whatsapp::Providers::WhatsappBaileysService::GroupParticipantNotAllowedError
    render json: { error: 'group_creator_not_modifiable' }, status: :unprocessable_entity
  rescue Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def ensure_group_contact
    return if @contact.group_type_group? && @contact.identifier.present?

    render json: { error: 'Contact is not a valid group' }, status: :unprocessable_entity
  end

  def group_members
    GroupMember.where(group_contact: @contact)
  end

  def create_params
    params.permit(participants: [])
  end

  def update_params
    params.permit(:role)
  end

  def channel
    @channel ||= @contact.group_channel
  end

  def inbox_phone_number
    channel&.phone_number
  end

  def inbox_admin?
    return false if @inbox_phone_number.blank?

    find_own_member&.role == 'admin'
  end

  def pin_own_member_on_first_page(paginated)
    return paginated unless @page == 1 && @inbox_phone_number.present?

    ids = paginated.pluck(:id)
    own = find_own_member
    return paginated if own.blank? || ids.include?(own.id)

    # Prepend own member; drop the last one so total per-page stays consistent
    [own] + paginated.where.not(id: own.id).limit(@per_page - 1).to_a
  end

  def find_own_member
    clean = @inbox_phone_number.delete('+')
    GroupMember.active
               .where(group_contact: @contact)
               .joins(:contact)
               .where('REPLACE(contacts.phone_number, \'+\', \'\') = ? OR RIGHT(REPLACE(contacts.phone_number, \'+\', \'\'), 8) = RIGHT(?, 8)',
                      clean, clean)
               .includes(:contact)
               .first
  end

  def format_participants(phone_numbers)
    Array(phone_numbers).map { |phone| "#{phone.to_s.delete('+')}@s.whatsapp.net" }
  end

  def jid_for_member(member)
    "#{member.contact.phone_number.to_s.delete('+')}@s.whatsapp.net"
  end

  def add_group_members(phone_numbers)
    inbox = @contact.contact_inboxes.first&.inbox
    Array(phone_numbers).each do |phone|
      normalized = normalize_phone(phone)
      next if normalized.blank?

      contact_inbox = ::ContactInboxWithContactBuilder.new(
        source_id: normalized.delete('+'),
        inbox: inbox,
        contact_attributes: { name: normalized, phone_number: normalized }
      ).perform
      next if contact_inbox.blank?

      member = GroupMember.find_or_initialize_by(group_contact: @contact, contact: contact_inbox.contact)
      member.update!(role: :member, is_active: true) unless member.persisted? && member.is_active?
    end
  end

  def normalize_phone(phone)
    cleaned = phone.to_s.strip
    return nil if cleaned.blank?

    cleaned.start_with?('+') ? cleaned : "+#{cleaned}"
  end
end
