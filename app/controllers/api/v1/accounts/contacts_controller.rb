class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 15
  protect_from_forgery with: :null_session

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :active, :search]
  before_action :fetch_contact, only: [:show, :update]

  def index
    @contacts_count = resolved_contacts.count
    @contacts = fetch_contact_last_seen_at(resolved_contacts)
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    contacts = resolved_contacts.where(
      'name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search',
      search: "%#{params[:q]}%"
    )
    @contacts_count = contacts.count
    @contacts = fetch_contact_last_seen_at(contacts)
  end

  # returns online contacts
  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker
                  .get_available_contact_ids(Current.account.id))
    @contacts_count = contacts.count
    @contacts = contacts.page(@current_page)
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      @contact = Current.account.contacts.new(contact_params)
      @contact.save!
      @contact_inbox = build_contact_inbox
    end
  end

  def update
    @contact.assign_attributes(contact_update_params)
    @contact.save!
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.record.errors.full_messages.join(', '),
      contact: Current.account.contacts.find_by(email: contact_params[:email])
    }, status: :unprocessable_entity
  end

  private

  def resolved_contacts
    @resolved_contacts ||= Current.account.contacts
                                  .where.not(email: [nil, ''])
                                  .or(Current.account.contacts.where.not(phone_number: [nil, '']))
                                  .order('LOWER(name)')
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_contact_last_seen_at(contacts)
    contacts.left_outer_joins(:conversations)
            .select('contacts.*, COUNT(conversations.id) as conversations_count, MAX(conversations.contact_last_seen_at) as last_seen_at')
            .group('contacts.id')
            .includes([{ avatar_attachment: [:blob] }, { contact_inboxes: [:inbox] }])
            .page(@current_page).per(RESULTS_PER_PAGE)
  end

  def build_contact_inbox
    return if params[:inbox_id].blank?

    inbox = Current.account.inboxes.find(params[:inbox_id])
    source_id = params[:source_id] || SecureRandom.uuid
    ContactInbox.create(contact: @contact, inbox: inbox, source_id: source_id)
  end

  def contact_params
    params.require(:contact).permit(:name, :email, :phone_number, additional_attributes: {}, custom_attributes: {})
  end

  def contact_custom_attributes
    return @contact.custom_attributes.merge(contact_params[:custom_attributes]) if contact_params[:custom_attributes]

    @contact.custom_attributes
  end

  def contact_update_params
    # we want the merged custom attributes not the original one
    contact_params.except(:custom_attributes).merge({ custom_attributes: contact_custom_attributes })
  end

  def fetch_contact
    @contact = Current.account.contacts.includes(contact_inboxes: [:inbox]).find(params[:id])
  end
end
