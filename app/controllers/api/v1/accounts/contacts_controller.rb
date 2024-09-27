class Api::V1::Accounts::ContactsController < Api::V1::Accounts::BaseController
  include Sift
  include AssignmentConcern
  include ContactConcern

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :active, :search, :filter]
  before_action :fetch_contact, only: [:show, :update, :destroy, :avatar, :contactable_inboxes, :destroy_custom_attributes]
  before_action :set_include_contact_inboxes, only: [:index, :search, :filter]

  def index
    @contacts_count = resolved_contacts.count
    @contacts = fetch_contacts(resolved_contacts)
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    contacts = resolved_contacts.where(
      'contacts.name ILIKE :search OR contacts.email ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier LIKE :search
        OR contacts.additional_attributes->>\'company_name\' ILIKE :search',
      search: "%#{params[:q].strip}%"
    )
    @contacts_count = contacts.count
    @contacts = fetch_contacts(contacts)
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
    Account::ContactsExportJob.perform_later(Current.account.id, column_names, Current.user.email)
    head :ok, message: I18n.t('errors.contacts.export.success')
  end

  # returns online contacts
  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker
                  .get_available_contact_ids(Current.account.id))
    @contacts_count = contacts.count
    @contacts = contacts.page(@current_page)
  end

  def show; end

  def filter
    result = ::Contacts::FilterService.new(params.permit!, current_user).perform
    contacts = result[:contacts]
    @contacts_count = result[:count]
    @contacts = fetch_contacts(contacts)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
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
    return render_error({ message: I18n.t('errors.assignment.permission') }, :forbidden) if change_assignee? && !change_assignee_permission?

    if change_product_agent? && !change_product_agent_permission?
      return render_error({ message: I18n.t('errors.assignment.product_permission') },
                          :forbidden)
    end

    @contact.assign_attributes(contact_update_params)
    @contact.save!
    process_avatar_from_url
    update_conversation
  end

  def destroy
    if ::OnlineStatusTracker.get_presence(
      @contact.account.id, 'Contact', @contact.id
    )
      return render_error({ message: I18n.t('contacts.online.delete', contact_name: @contact.name.titleize) },
                          :unprocessable_entity)
    end

    @contact.destroy!
    head :ok
  end

  def avatar
    @contact.avatar.purge if @contact.avatar.attached?
    @contact
  end

  def available_products
    result = ::Contacts::FilterService.new(params.permit!, current_user).perform
    contacts = result[:contacts]
    products = contacts.joins(:product).order('products.short_name')
                       .map do |contact|
      { name: contact.product.name, short_name: contact.product.short_name,
        id: contact.product.id }
    end.uniq
    render json: products
  end

  private

  def set_current_page
    @current_page = params[:page] || 1
  end

  def permitted_params
    params.permit(:name, :identifier, :email, :phone_number, :stage_id, :avatar, :blocked, :assignee_id, :team_id, :product_id, :po_date,
                  :po_note, :po_value, :po_agent_id, :po_team_id, :avatar_url, additional_attributes: {}, custom_attributes: {})
  end

  def contact_update_params
    # we want the merged custom attributes not the original one
    permitted_params.except(:custom_attributes, :avatar_url).merge({ custom_attributes: contact_custom_attributes })
  end

  def render_error(error, error_status)
    render json: error, status: error_status
  end
end
