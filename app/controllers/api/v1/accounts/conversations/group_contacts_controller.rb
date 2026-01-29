class Api::V1::Accounts::Conversations::GroupContactsController < Api::V1::Accounts::Conversations::BaseController
  RESULTS_PER_PAGE = 100

  before_action :ensure_group_conversation, only: [:create, :update, :destroy]
  before_action :validate_contact_ids, only: [:create, :update, :destroy]
  before_action :set_current_page, only: [:show]

  def show
    @total_count = @conversation.group_contacts.count
    @group_contacts = @conversation.group_contacts.includes(:contact).page(@current_page).per(RESULTS_PER_PAGE)
  end

  def create
    ActiveRecord::Base.transaction do
      @group_contacts = contacts_to_be_added_ids.map { |contact_id| @conversation.group_contacts.find_or_create_by!(contact_id: contact_id) }
    end
  end

  def update
    ActiveRecord::Base.transaction do
      contacts_to_be_added_ids.each { |contact_id| @conversation.group_contacts.find_or_create_by!(contact_id: contact_id) }
      contacts_to_be_removed_ids.each { |contact_id| @conversation.group_contacts.find_by(contact_id: contact_id)&.destroy! }
    end
    @group_contacts = @conversation.group_contacts.includes(:contact)
    render action: 'show'
  end

  def destroy
    ActiveRecord::Base.transaction do
      params[:contact_ids].each { |contact_id| @conversation.group_contacts.find_by(contact_id: contact_id)&.destroy! }
    end
    head :ok
  end

  private

  def ensure_group_conversation
    render json: { error: 'Conversation must be a group' }, status: :unprocessable_entity unless @conversation.group?
  end

  def validate_contact_ids
    return if params[:contact_ids].is_a?(Array)

    render json: { error: 'contact_ids must be an array' }, status: :unprocessable_entity
  end

  def contacts_to_be_added_ids
    params[:contact_ids] - current_group_contact_ids
  end

  def contacts_to_be_removed_ids
    current_group_contact_ids - params[:contact_ids]
  end

  def current_group_contact_ids
    @current_group_contact_ids ||= @conversation.group_contacts.pluck(:contact_id)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
