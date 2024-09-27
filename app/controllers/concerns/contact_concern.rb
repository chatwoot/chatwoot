module ContactConcern
  include Sift
  sort_on :email, type: :string
  sort_on :initial_channel_type, type: :string
  sort_on :name, internal_name: :order_on_name, type: :scope, scope_params: [:direction]
  sort_on :phone_number, type: :string
  sort_on :product_name, internal_name: :order_on_product_id, type: :scope, scope_params: [:direction]
  sort_on :po_value, internal_name: :order_on_po_value, type: :scope, scope_params: [:direction]
  sort_on :po_date, type: :date
  sort_on :po_note, type: :string
  sort_on :last_activity_at, internal_name: :order_on_last_activity_at, type: :scope, scope_params: [:direction]
  sort_on :created_at, internal_name: :order_on_created_at, type: :scope, scope_params: [:direction]
  sort_on :updated_at, internal_name: :order_on_updated_at, type: :scope, scope_params: [:direction]
  sort_on :last_stage_changed_at, internal_name: :order_on_last_stage_changed_at, type: :scope, scope_params: [:direction]
  sort_on :company, internal_name: :order_on_company_name, type: :scope, scope_params: [:direction]
  sort_on :stage_name, internal_name: :order_on_stage_id, type: :scope, scope_params: [:direction]
  sort_on :assignee_name, internal_name: :order_on_assignee_id, type: :scope, scope_params: [:direction]
  sort_on :team_name, internal_name: :order_on_team_id, type: :scope, scope_params: [:direction]
  sort_on :city, internal_name: :order_on_city, type: :scope, scope_params: [:direction]
  sort_on :country, internal_name: :order_on_country_name, type: :scope, scope_params: [:direction]
  RESULTS_PER_PAGE = 15
  def resolved_contacts
    return @resolved_contacts if @resolved_contacts

    @resolved_contacts = Current.account.contacts.resolved_contacts

    @resolved_contacts = @resolved_contacts.tagged_with(params[:labels], any: true) if params[:labels].present?
    if params[:stage_type].present?
      @resolved_contacts = ::Contacts::FilterService.new(params.permit!, current_user).contacts_by_stage_type(@resolved_contacts)
    end
    if params[:stage_code].present?
      @resolved_contacts = ::Contacts::FilterService.new(params.permit!, current_user).contacts_by_stage_code(@resolved_contacts)
    end

    @resolved_contacts
  end

  def fetch_contacts(contacts)
    contacts_with_avatar = filtrate(contacts)
                           .includes(:notes, :stage, :team, :assignee, :conversation_plans, [{ avatar_attachment: [:blob] }])

    contacts_with_avatar = contacts_with_avatar.page(@current_page).per(RESULTS_PER_PAGE) if @current_page.to_i.positive?

    return contacts_with_avatar.includes([{ contact_inboxes: [:inbox] }]) if @include_contact_inboxes

    contacts_with_avatar
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    ContactInboxBuilder.new(
      contact: @contact,
      inbox: inbox,
      source_id: params[:source_id]
    ).perform
  end

  def contact_custom_attributes
    return @contact.custom_attributes.merge(permitted_params[:custom_attributes]) if permitted_params[:custom_attributes]

    @contact.custom_attributes
  end

  def set_include_contact_inboxes
    @include_contact_inboxes = if params[:include_contact_inboxes].present?
                                 params[:include_contact_inboxes] == 'true'
                               else
                                 true
                               end
  end

  def fetch_contact
    @contact = Current.account.contacts.includes(contact_inboxes: [:inbox], conversation_plans: [:conversation]).find(params[:id])
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end
end
