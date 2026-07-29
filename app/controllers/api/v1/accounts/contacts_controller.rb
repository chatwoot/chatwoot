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
  sort_on :document_number, internal_name: :order_on_document_number, type: :scope, scope_params: [:direction]
  sort_on :assigned_agent, internal_name: :order_on_assigned_agent, type: :scope, scope_params: [:direction]
  sort_on :identifier, internal_name: :order_on_identifier, type: :scope, scope_params: [:direction]
  sort_on :blocked, internal_name: :order_on_blocked, type: :scope, scope_params: [:direction]
  sort_on :labels, internal_name: :order_on_labels, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 15
  ALLOWED_PER_PAGE = [15, 25, 50, 100].freeze

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :active, :search, :filter]
  before_action :set_results_per_page, only: [:index, :active, :search, :filter]
  before_action :fetch_contact, only: [:show, :update, :destroy, :avatar, :contactable_inboxes, :destroy_custom_attributes]
  before_action :set_include_contact_inboxes, only: [:index, :active, :search, :filter, :show, :update]

  def index
    @contacts = fetch_contacts(resolved_contacts)
    @contacts_count = @contacts.total_count
    preload_contact_list_labels
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    contacts = Current.account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR contacts.identifier ILIKE :search OR contacts.document_number ILIKE :search OR additional_attributes->>'company_name' ILIKE :search",
      search: "%#{params[:q].strip}%"
    )
    @contacts = fetch_contacts_with_has_more(contacts)
    preload_contact_list_labels
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
    filter_params = {
      payload: params.permit!['payload'],
      label: params.permit!['label'],
      # Rails reserves params[:format] for request format (e.g. json) — use export_format
      export_format: params[:export_format]
    }
    Account::ContactsExportJob.perform_later(Current.account.id, Current.user.id, column_names, filter_params)
    head :ok, message: I18n.t('errors.contacts.export.success')
  end

  # returns online contacts
  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker
                  .get_available_contact_ids(Current.account.id))
    @contacts = fetch_contacts(contacts)
    @contacts_count = @contacts.total_count
    preload_contact_list_labels
  end

  def show
    set_contact_conversation_metrics
  end

  def filter
    result = ::Contacts::FilterService.new(Current.account, Current.user, params.permit!).perform
    contacts = result[:contacts]
    @contacts_count = result[:count]
    @contacts = fetch_contacts(contacts)
    preload_contact_list_labels
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
      @contact = Current.account.contacts.new(permitted_params.except(:avatar_url))
      @contact.save!
      @contact_inbox = build_contact_inbox
      process_avatar_from_url
    end
  end

  def update
    @contact.assign_attributes(contact_update_params)
    @contact.assigned_agent_id = permitted_assigned_agent_id
    @contact.save!
    process_avatar_from_url
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

  def set_results_per_page
    requested = params[:per_page].to_i
    @results_per_page = ALLOWED_PER_PAGE.include?(requested) ? requested : RESULTS_PER_PAGE
  end

  def fetch_contacts(contacts)
    # Build includes hash to avoid separate query when contact_inboxes are needed
    includes_hash = { avatar_attachment: [:blob] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    apply_contact_sort(contacts)
      .includes(includes_hash)
      .page(@current_page)
      .per(@results_per_page)
  end

  def fetch_contacts_with_has_more(contacts)
    includes_hash = { avatar_attachment: [:blob] }
    includes_hash[:contact_inboxes] = { inbox: :channel } if @include_contact_inboxes

    # Calculate offset manually to fetch one extra record for has_more check
    offset = (@current_page.to_i - 1) * @results_per_page
    results = apply_contact_sort(contacts)
              .includes(includes_hash)
              .offset(offset)
              .limit(@results_per_page + 1)
              .to_a

    @has_more = results.size > @results_per_page
    results = results.first(@results_per_page) if @has_more
    @contacts_count = results.size
    results
  end

  def apply_contact_sort(contacts)
    sort_param = params[:sort].to_s
    match = sort_param.match(/\A(-?)custom:(.+)\z/)
    return filtrate(contacts) unless match

    direction = match[1] == '-' ? 'DESC' : 'ASC'
    attribute_key = match[2]
    definition = contact_custom_attribute_definitions[attribute_key]
    return filtrate(contacts) unless definition

    # Formula attrs always store computed numbers; treat as numeric even if mistyped as text.
    numeric = definition.number? || definition.currency? || definition.percent? || definition.formula?
    contacts.order_on_custom_attribute(attribute_key, direction, numeric: numeric)
  end

  def contact_custom_attribute_keys
    contact_custom_attribute_definitions.keys
  end

  def contact_custom_attribute_definitions
    @contact_custom_attribute_definitions ||= Current.account.custom_attribute_definitions
                                                     .contact_attribute
                                                     .index_by(&:attribute_key)
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
    params.permit(:name, :identifier, :document_number, :email, :phone_number, :avatar, :blocked, :avatar_url, additional_attributes: {}, custom_attributes: {})
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
    permitted_params.except(:custom_attributes, :avatar_url)
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
    contact_scope = contact_scope.includes(contact_inboxes: [:inbox]) if @include_contact_inboxes
    @contact = contact_scope.find(params[:id])
  end

  def process_avatar_from_url
    ::Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url]) if params[:avatar_url].present?
  end

  def render_error(error, error_status)
    render json: error, status: error_status
  end

  def permitted_assigned_agent_id
    return @contact.assigned_agent_id unless params.key?(:assigned_agent_id)

    requested_id = params[:assigned_agent_id].presence

    return requested_id if admin?

    current_user_id = Current.user&.id
    current_owner_id = @contact.assigned_agent_id

    # Agents can self-assign unassigned contacts
    if current_owner_id.blank? && requested_id.to_i == current_user_id
      current_user_id
    # Agents can release contacts assigned to themselves
    elsif current_owner_id == current_user_id && requested_id.blank?
      nil
    else
      # Silently ignore any other change attempt
      @contact.assigned_agent_id
    end
  end

  def admin?
    Current.account_user&.administrator?
  end

  def preload_contact_list_labels
    contact_records = @contacts.respond_to?(:to_a) ? @contacts.to_a : Array(@contacts)
    @contact_labels_by_id = Contacts::LabelsPreloader.call(
      account: Current.account,
      contact_ids: contact_records.map(&:id)
    )
  end

  def set_contact_conversation_metrics
    conversations = Current.account.conversations.where(contact_id: @contact.id)
    conversations = Conversations::PermissionFilterService.new(
      conversations,
      Current.user,
      Current.account
    ).perform

    status_counts = conversations.reorder(nil).group(:status).count
    open_statuses = [Conversation.statuses[:open], Conversation.statuses[:pending]]
    open_count = open_statuses.sum { |status| status_counts[status].to_i }

    @contact_conversation_metrics = {
      conversations_count: status_counts.values.sum,
      open_conversations_count: open_count,
      resolved_conversations_count: status_counts[Conversation.statuses[:resolved]].to_i
    }
  end
end

Api::V1::Accounts::ContactsController.prepend_mod_with('Api::V1::Accounts::ContactsController')
