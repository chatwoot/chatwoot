class Api::V1::Accounts::Contacts::GroupMembersController < Api::V1::Accounts::Contacts::BaseController
  include GroupChannelResolver

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
    @own_member = Whatsapp::Session::Owner.group_member(channel, @contact)
    @is_inbox_admin = @own_member&.role == 'admin'

    paginated = base_query.order(role: :desc, id: :asc)
                          .offset((@page - 1) * @per_page)
                          .limit(@per_page)

    @group_members = pin_own_member_on_first_page(paginated)
  end

  def create
    authorize @contact, :update?
    participants = create_params[:participants]
    return render json: { error: 'participants_required' }, status: :unprocessable_entity if participants.blank?

    answer = channel.update_group_participants(@contact.identifier, format_participants(participants), 'add')
    add_group_members(participants_that_landed(participants, answer))
    head :ok
  rescue Whatsapp::Session::Errors::Error => e
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
  rescue Whatsapp::Session::Errors::GroupParticipantNotAllowed
    render json: { error: 'group_creator_not_modifiable' }, status: :unprocessable_entity
  rescue Whatsapp::Session::Errors::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    authorize @contact, :update?

    member = group_members.find(params[:id])
    channel.update_group_participants(@contact.identifier, [jid_for_member(member)], 'remove')
    member.update!(is_active: false)
    head :ok
  rescue Whatsapp::Session::Errors::GroupParticipantNotAllowed
    render json: { error: 'group_creator_not_modifiable' }, status: :unprocessable_entity
  rescue Whatsapp::Session::Errors::Error => e
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

  def inbox_phone_number
    channel.phone_number
  end

  def pin_own_member_on_first_page(paginated)
    return paginated unless @page == 1

    ids = paginated.pluck(:id)
    own = @own_member
    return paginated if own.blank? || ids.include?(own.id)

    # Prepend own member; drop the last one so total per-page stays consistent
    [own] + paginated.where.not(id: own.id).limit(@per_page - 1).to_a
  end

  def format_participants(phone_numbers)
    Array(phone_numbers).map { |phone| "#{phone.to_s.delete('+')}@s.whatsapp.net" }
  end

  # A group roster can name a participant WhatsApp only ever gave a LID for, and those
  # contacts have no phone number at all: building a phone JID from one produced
  # `@s.whatsapp.net`, which no provider accepts, so the member could not be promoted,
  # demoted or removed. Address is where the rule for which id a contact is reachable by
  # already lives.
  def jid_for_member(member)
    address = Whatsapp::Session::Model::Address.for_contact(member.contact)
    raise Whatsapp::Session::Errors::InvalidPayload, 'group member has no WhatsApp address' if address.nil?

    address.to_jid
  end

  # WhatsApp refuses participants one at a time and answers with a row each, so an `add`
  # of several can come back having added some of them. Writing all of them to the roster
  # shows the operator members who are not in the group, until the next scheduled sync
  # takes them out again.
  #
  # A provider that does not answer in rows has told us nothing to filter on, and the
  # Baileys one answers with the list it was handed: there, everything it did not raise
  # for counts as added, which is what it meant before this.
  def participants_that_landed(phone_numbers, answer)
    verdicts = verdicts_by_number(answer)

    Array(phone_numbers).reject { |phone| refused_outright?(verdicts, phone) }
  end

  # Refused means refused in every row that speaks for this submission.
  def refused_outright?(verdicts, phone)
    spoken_for = verdicts_about(verdicts, phone)

    spoken_for.present? && spoken_for.all? { |_, status| status == 'failed' }
  end

  # A row naming the number exactly as it was submitted is the verdict on that
  # submission: the provider answers one row per participant asked, under the address it
  # was asked with. Submitting a line under both of its spellings therefore gets a verdict
  # each, and reading them together would write the refused spelling to the roster on the
  # strength of the other one.
  #
  # Only where no row spells it the way it was submitted do the other spellings speak for
  # it: a Brazilian or Argentinian line is written with or without the ninth digit
  # depending on who is spelling it, and a provider that answers under its own spelling
  # has still answered about this participant.
  def verdicts_about(verdicts, phone)
    as_submitted = Whatsapp::Session::PhoneMatch.digits(phone)
    named = verdicts.select { |number, _| number == as_submitted }
    return named if named.present?

    verdicts.select { |number, _| Whatsapp::Session::PhoneMatch.same_number?(number, phone) }
  end

  def verdicts_by_number(answer)
    Array(answer).filter_map do |row|
      # Only a row is a row. The Baileys path answers with the list it was handed, and a
      # backend that answers nothing at all answers `true`.
      next unless row.is_a?(Hash)

      row = row.stringify_keys
      # A row carrying no verdict has not said this participant is in the group, and it
      # has not said they are out of it either: only `failed` refuses.
      [phone_in(row['address']), row['status'].to_s]
    end
  end

  # An `add` is asked by phone and answered under the address it was asked with, so a row
  # names a number. A LID is a separate namespace that happens to be written in digits
  # too, and reading one as a phone number would speak for a line it says nothing about.
  def phone_in(address)
    return nil unless address.is_a?(Hash)

    address = address.stringify_keys
    return nil if address['kind'].present? && address['kind'].to_s != 'phone'

    Whatsapp::Session::PhoneMatch.digits(address['id'])
  end

  # Into the inbox the addition was performed as, which is the one that now has the new
  # members in its copy of the group.
  def add_group_members(phone_numbers)
    inbox = group_contact_inbox&.inbox
    one_per_person(phone_numbers).each do |normalized|
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

  # A roster is about people, and a Brazilian or Argentinian number has two spellings of the
  # same person: with the ninth digit and without it. Submitting both wrote two contacts and
  # two rows, and the operator saw the group with one member more than it has. Promoting or
  # removing one of those rows did nothing to the other.
  #
  # The first spelling submitted wins, because nothing here knows which one the person's
  # own device uses and the scheduled participant sync rewrites the roster from what
  # WhatsApp answers anyway.
  #
  # This is the cheap layer of the two the issue names. The correct one is making contact
  # resolution by phone reach both spellings, which lives in `ContactInboxWithContactBuilder`
  # and is shared with every channel, so it wants its own change and its own tests.
  def one_per_person(phone_numbers)
    Array(phone_numbers).filter_map { |phone| normalize_phone(phone) }.each_with_object([]) do |number, kept|
      kept << number unless kept.any? { |seen| Whatsapp::Session::PhoneMatch.same_number?(seen, number) }
    end
  end

  def normalize_phone(phone)
    cleaned = phone.to_s.strip
    return nil if cleaned.blank?

    cleaned.start_with?('+') ? cleaned : "+#{cleaned}"
  end
end
