# rubocop:disable Metrics/ClassLength
class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  include Sift
  sort_on :email, type: :string
  sort_on :name, internal_name: :order_on_name, type: :scope, scope_params: [:direction]
  sort_on :phone_number, type: :string
  sort_on :last_activity_at, internal_name: :order_on_last_activity_at, type: :scope, scope_params: [:direction]
  sort_on :created_at, internal_name: :order_on_created_at, type: :scope, scope_params: [:direction]
  sort_on :company_name, internal_name: :order_on_company_name, type: :scope, scope_params: [:direction]
  sort_on :city, internal_name: :order_on_city, type: :scope, scope_params: [:direction]
  sort_on :country, internal_name: :order_on_country_name, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 15

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :active, :search, :filter]
  before_action :fetch_contact, only: [:show, :update, :destroy, :avatar, :contactable_inboxes, :destroy_custom_attributes]
  before_action :set_include_contact_inboxes, only: [:index, :active, :search, :filter, :show, :update]

  def index
    @contacts = fetch_contacts(resolved_contacts)
    @contacts_count = @contacts.total_count
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    search_query = params[:q].strip
    contacts = Current.account.contacts.left_outer_joins(:contact_emails)
    contacts = contacts.where(search_conditions, search: "%#{search_query}%", contact_id: search_query.to_i)
    contacts = prioritize_exact_contact_id_match(contacts.distinct, search_query)
    @contacts = fetch_contacts_with_has_more(contacts)
  end

  def import
    render json: { error: I18n.t('errors.contacts.import.failed') }, status: :unprocessable_entity and return if params[:import_file].blank?

    ActiveRecord::Base.transaction do
      import = Current.account.data_imports.create!(data_type: 'contacts')
      import.import_file.attach(params[:import_file])
    end

    head :ok
  end

  def export
    column_names = params['column_names']
    filter_params = { :payload => params.permit!['payload'], :label => params.permit!['label'] }
    Account::ContactsExportJob.perform_later(Current.account.id, Current.user.id, column_names, filter_params)
    head :ok, message: I18n.t('errors.contacts.export.success')
  end

  # returns online contacts
  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker
                  .get_available_contact_ids(Current.account.id))
    @contacts = fetch_contacts(contacts)
    @contacts_count = @contacts.total_count
  end

  def show; end

  def filter
    result = ::Contacts::FilterService.new(Current.account, Current.user, params.permit!).perform
    contacts = result[:contacts]
    @contacts_count = result[:count]
    @contacts = fetch_contacts(contacts)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def contactable_inboxes
    @all_contactable_inboxes = Contacts::ContactableInboxesService.new(contact: @contact).get
    @contactable_inboxes = @all_contactable_inboxes.select { |contactable_inbox| policy(contactable_inbox[:inbox]).show? }
  end

  # TODO : refactor this method into dedicated contacts/custom_attributes controller class and routes
  def destroy_custom_attributes
    @contact.custom_attributes = @contact.custom_attributes.excluding(params[:custom_attributes])
    @contact.save!
  end

  def create
    ActiveRecord::Base.transaction do
      @contact = Current.account.contacts.new(contact_create_params)
      assign_primary_email_from_identities(@contact)
      @contact.save!
      replace_contact_emails if emails_param_provided?
      @contact_inbox = build_contact_inbox
      process_avatar_from_url
    end
  end

  def update
    ActiveRecord::Base.transaction do
      @contact.assign_attributes(contact_update_params)
      assign_primary_email_from_identities(@contact)
      @contact.save!
      replace_contact_emails if emails_param_provided?
      process_avatar_from_url
    end
  end

  def destroy
    if ::OnlineStatusTracker.get_presence(
      @contact.account.id, 'Contact', @contact.id
    )
      return render_error({ message: I18n.t('contacts.online.delete', contact_name: @contact.name.capitalize) },
                          :unprocessable_entity)
    end

    @contact.destroy!
    head :ok
  end

  def avatar
    @contact.avatar.purge if @contact.avatar.attached?
    @contact
  end

  private

  # TODO: Move this to a finder class
  def resolved_contacts
    return @resolved_contacts if @resolved_contacts

    @resolved_contacts = Current.account.contacts.resolved_contacts(use_crm_v2: Current.account.feature_enabled?('crm_v2'))

    @resolved_contacts = @resolved_contacts.tagged_with(params[:labels], any: true) if params[:labels].present?
    @resolved_contacts
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_contacts(contacts)
    # Build includes hash to avoid separate query when contact_inboxes are needed
    includes_hash = { avatar_attachment: [:blob], contact_emails: [] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    filtrate(contacts)
      .includes(includes_hash)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def fetch_contacts_with_has_more(contacts)
    includes_hash = { avatar_attachment: [:blob], contact_emails: [] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    # Calculate offset manually to fetch one extra record for has_more check
    offset = (@current_page.to_i - 1) * RESULTS_PER_PAGE
    results = filtrate(contacts)
              .includes(includes_hash)
              .offset(offset)
              .limit(RESULTS_PER_PAGE + 1)
              .to_a

    @has_more = results.size > RESULTS_PER_PAGE
    results = results.first(RESULTS_PER_PAGE) if @has_more
    @contacts_count = results.size
    results
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

  def permitted_params
    params.permit(
      :name, :identifier, :email, :phone_number, :avatar, :blocked, :avatar_url,
      emails: [], additional_attributes: {}, custom_attributes: {}
    )
  end

  def contact_create_params
    permitted_params.except(:avatar_url, :emails)
  end

  def contact_custom_attributes
    return @contact.custom_attributes.merge(permitted_params[:custom_attributes]) if permitted_params[:custom_attributes]

    @contact.custom_attributes
  end

  def contact_additional_attributes
    return @contact.additional_attributes.merge(permitted_params[:additional_attributes]) if permitted_params[:additional_attributes]

    @contact.additional_attributes
  end

  def contact_update_params
    permitted_params.except(:custom_attributes, :avatar_url, :emails)
                    .merge({ custom_attributes: contact_custom_attributes })
                    .merge({ additional_attributes: contact_additional_attributes })
  end

  def set_include_contact_inboxes
    @include_contact_inboxes = if params[:include_contact_inboxes].present?
                                 params[:include_contact_inboxes] == 'true'
                               else
                                 true
                               end
  end

  def fetch_contact
    contact_scope = Current.account.contacts
    contact_scope = contact_scope.includes(:contact_emails)
    contact_scope = contact_scope.includes(contact_inboxes: [:inbox]) if @include_contact_inboxes
    @contact = contact_scope.find(params[:id])
  end

  def emails_param_provided?
    permitted_params.key?(:emails)
  end

  def normalized_emails_param
    @normalized_emails_param ||= Array(permitted_params[:emails]).filter_map do |email|
      normalized_email = email.to_s.strip.downcase
      normalized_email.presence
    end.uniq
  end

  def assign_primary_email_from_identities(contact)
    return unless emails_param_provided?

    contact.email = normalized_emails_param.first
  end

  def replace_contact_emails
    Contacts::ReplaceContactEmails.new(contact: @contact, emails: permitted_params[:emails]).perform
  end

  def search_conditions
    base_conditions = [
      'contacts.name ILIKE :search',
      'contacts.email ILIKE :search',
      'contact_emails.email ILIKE :search',
      'contacts.phone_number ILIKE :search',
      'contacts.identifier LIKE :search'
    ]

    base_conditions << 'contacts.id = :contact_id' if numeric_contact_query?(params[:q].to_s.strip)
    base_conditions.join(' OR ')
  end

  def prioritize_exact_contact_id_match(contacts, search_query)
    return contacts unless numeric_contact_query?(search_query)

    contact_id = search_query.to_i
    priority_select = Contact.send(
      :sanitize_sql_array,
      ['contacts.*, CASE WHEN contacts.id = ? THEN 0 ELSE 1 END AS exact_match_priority', contact_id]
    )

    contacts.reselect(Arel.sql(priority_select))
            .order(Arel.sql('exact_match_priority ASC, contacts.id DESC'))
  end

  def numeric_contact_query?(search_query)
    search_query.match?(/\A\d+\z/)
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end

  def render_error(error, error_status)
    render json: error, status: error_status
  end
end
# rubocop:enable Metrics/ClassLength
