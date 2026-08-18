class Public::Api::V1::Portals::TicketsController < Public::Api::V1::Portals::BaseController
  # A magic link is only good for reaching one portal's ticket list, and only for
  # 15 minutes. Once redeemed the session cookie carries the identity instead.
  ACCESS_TOKEN_VALIDITY = 15.minutes
  SESSION_VALIDITY = 30.minutes

  before_action :ensure_custom_domain_request
  before_action :portal
  before_action :set_portal_locale
  before_action :set_portal_layout
  before_action :set_view_variant
  before_action :ensure_portal_feature_enabled
  before_action :ensure_tickets_enabled
  before_action :set_authenticated_contact, only: [:index, :show]
  before_action :ensure_authenticated_contact, only: [:index, :show]
  layout 'portal'

  def index
    @tickets = contact_tickets.order(updated_at: :desc)
  end

  def show
    @ticket = contact_tickets.find_by(id: params[:id])
    return render_404 if @ticket.blank?

    @messages = @ticket.conversation.messages.chat.includes(:sender).order(created_at: :asc)
  end

  def new
    @ticket_types = Ticket::TYPES
    @submission = { name: '', email: '', subject: '', ticket_type: nil, description: '' }
  end

  def create
    @ticket_types = Ticket::TYPES
    @submission = submission_params
    @errors = submission_errors
    return render :new, status: :unprocessable_entity if @errors.any?

    @ticket = build_ticket
  end

  def access; end

  def send_access_link
    contact = @portal.account.contacts.from_email(submission_params[:email])
    deliver_access_link(contact) if contact.present?

    render :access_sent
  end

  def verify
    contact = contact_from_token
    if contact.blank?
      @error = I18n.t('public_portal.tickets.access.invalid_token')
      return render :access, status: :unauthorized
    end

    session[:portal_ticket_access] = {
      'portal_id' => @portal.id,
      'contact_id' => contact.id,
      'expires_at' => SESSION_VALIDITY.from_now.to_i
    }
    redirect_to "/hc/#{@portal.slug}/tickets"
  end

  private

  def set_portal_locale
    @locale = @portal.default_locale
  end

  def ensure_tickets_enabled
    render_404 unless helpers.portal_tickets_enabled?(@portal)
  end

  def widget_inbox
    @widget_inbox ||= @portal.channel_web_widget&.inbox
  end

  # ----------------------------------------------------------------------
  # Ticket submission

  def build_ticket
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: SecureRandom.uuid,
      inbox: widget_inbox,
      contact_attributes: { name: @submission[:name].presence, email: @submission[:email] }
    ).perform

    conversation = ::ConversationBuilder.new(params: ActionController::Parameters.new, contact_inbox: contact_inbox).perform
    create_description_message(conversation, contact_inbox.contact)

    conversation.create_ticket!(account_id: @portal.account_id, subject: @submission[:subject], ticket_type: @submission[:ticket_type])
  end

  def create_description_message(conversation, contact)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      sender: contact,
      content: @submission[:description],
      message_type: :incoming
    )
  end

  def submission_errors
    errors = {}
    errors[:email] = I18n.t('public_portal.tickets.errors.email') unless @submission[:email].match?(Devise.email_regexp)
    errors[:subject] = I18n.t('public_portal.tickets.errors.subject') if @submission[:subject].blank?
    errors[:description] = I18n.t('public_portal.tickets.errors.description') if @submission[:description].blank?
    errors
  end

  def submission_params
    permitted = params.permit(:name, :email, :subject, :ticket_type, :description)
    {
      name: permitted[:name].to_s.strip,
      email: permitted[:email].to_s.strip.downcase,
      subject: permitted[:subject].to_s.strip,
      ticket_type: Ticket::TYPES.include?(permitted[:ticket_type]) ? permitted[:ticket_type] : nil,
      description: permitted[:description].to_s.strip
    }
  end

  # ----------------------------------------------------------------------
  # Magic link access

  def deliver_access_link(contact)
    token = contact.signed_id(purpose: token_purpose, expires_in: ACCESS_TOKEN_VALIDITY)
    verify_url = "#{request.base_url}/hc/#{@portal.slug}/tickets/verify?token=#{CGI.escape(token)}"

    PortalTicketAccessMailer.access_link(portal: @portal, contact: contact, verify_url: verify_url).deliver_later
  end

  def contact_from_token
    contact = ::Contact.find_signed(params[:token].to_s, purpose: token_purpose)
    contact if contact&.account_id == @portal.account_id
  end

  def token_purpose
    "portal_ticket_access_#{@portal.id}"
  end

  def set_authenticated_contact
    access = session[:portal_ticket_access]
    return if access.blank?
    return if access['portal_id'] != @portal.id || access['expires_at'].to_i < Time.current.to_i

    @contact = @portal.account.contacts.find_by(id: access['contact_id'])
  end

  def ensure_authenticated_contact
    return if @contact.present?

    session.delete(:portal_ticket_access)
    redirect_to "/hc/#{@portal.slug}/tickets/access"
  end

  def contact_tickets
    ::Ticket.joins(:conversation)
            .where(account_id: @portal.account_id, conversations: { contact_id: @contact.id })
            .includes(:conversation)
  end
end
