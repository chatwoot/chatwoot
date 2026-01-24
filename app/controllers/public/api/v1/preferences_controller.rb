# CommMate: Public preferences controller for campaign subscription management
# Allows contacts to manage their label subscriptions via secure token links
class Public::Api::V1::PreferencesController < PublicController
  include SwitchLocale

  before_action :set_contact_from_token
  around_action :switch_locale_for_preferences
  before_action :set_campaign_labels, only: [:show]
  layout 'preferences'
  helper_method :contact_identifier_text

  def show
    return if render_validation_error
    return dispatch_action if action_requested?

    # Show full preferences page
    # Note: contact.labels returns tags (acts-as-taggable-on) with 'name' column
    @contact_labels = @contact.labels.pluck(:name)
    render :show
  end

  def update
    return if render_validation_error

    params[:unsubscribe_all].present? ? handle_unsubscribe_all : update_preferences
  end

  private

  def render_validation_error
    return render_error_page(:expired) if @token_error == :expired
    return render_error_page(:invalid) if @token_error == :invalid
    return render_error_page(:contact_not_found) unless @contact
    return render_error_page(:account_unavailable) unless @account&.active?

    false
  end

  def action_requested?
    params[:add].present? || params[:remove].present? || params[:unsubscribe_all].present?
  end

  def dispatch_action
    return handle_subscribe(params[:add]) if params[:add].present?
    return handle_unsubscribe(params[:remove]) if params[:remove].present?

    handle_unsubscribe_all if params[:unsubscribe_all].present?
  end

  def set_contact_from_token
    decoded = ContactPreferenceTokenService.new(token: params[:token]).decode_token

    if decoded[:error]
      @token_error = decoded[:error]
      return
    end

    @account = Account.find_by(id: decoded[:account_id])
    @contact = @account&.contacts&.find_by(id: decoded[:contact_id])
  end

  def set_campaign_labels
    return unless @account

    @campaign_labels = @account.labels.campaign_labels
  end

  def handle_subscribe(label_id)
    label = find_campaign_label(label_id)
    return render_error_page(:label_not_found) unless label

    @contact.add_labels([label.title])
    @action = :subscribed
    @label = label
    render :subscribe
  end

  def handle_unsubscribe(label_id)
    label = find_campaign_label(label_id)
    return render_error_page(:label_not_found) unless label

    remove_label_from_contact(label.title)
    @action = :unsubscribed
    @label = label
    render :unsubscribe
  end

  def handle_unsubscribe_all
    campaign_label_titles = @account.labels.campaign_labels.pluck(:title)

    # Get all current labels and remove only campaign labels in one operation
    current_labels = @contact.labels.pluck(:name)
    non_campaign_labels = current_labels - campaign_label_titles
    @contact.update_labels(non_campaign_labels)

    @removed_count = campaign_label_titles.count
    render :unsubscribe_all
  end

  def update_preferences
    selected_labels = params[:labels] || []
    campaign_label_titles = @account.labels.campaign_labels.pluck(:title)

    # Remove all campaign labels first
    campaign_label_titles.each { |title| remove_label_from_contact(title) }

    # Add selected labels
    labels_to_add = campaign_label_titles & selected_labels
    @contact.add_labels(labels_to_add) if labels_to_add.any?

    @success = true
    @contact_labels = @contact.reload.labels.pluck(:name)
    @campaign_labels = @account.labels.campaign_labels
    render :show
  end

  def find_campaign_label(label_identifier)
    # Support lookup by ID or title
    @account.labels.campaign_labels.find_by(id: label_identifier) ||
      @account.labels.campaign_labels.find_by(title: label_identifier)
  end

  def remove_label_from_contact(label_title)
    current_labels = @contact.labels.pluck(:name)
    new_labels = current_labels - [label_title]
    @contact.update_labels(new_labels)
  end

  def render_error_page(error_type)
    @error_type = error_type
    @error_message = error_message_for(error_type)
    render :error, status: error_status_for(error_type)
  end

  def error_message_for(error_type)
    I18n.t("public_preferences.errors.#{error_type}", default: I18n.t('public_preferences.errors.generic'))
  end

  def error_status_for(error_type)
    case error_type
    when :expired, :invalid
      :gone
    when :contact_not_found, :label_not_found
      :not_found
    when :account_unavailable
      :service_unavailable
    else
      :bad_request
    end
  end

  def contact_identifier_text(contact)
    return '' unless contact

    identifiers = []
    identifiers << contact.email if contact.email.present?
    identifiers << contact.phone_number if contact.phone_number.present?

    return '' if identifiers.empty?

    t('public_preferences.contact_info', identifier: identifiers.join(' • '))
  end

  # Locale detection for public preferences pages
  # Priority: query param > account locale > browser Accept-Language > default
  def switch_locale_for_preferences(&)
    locale = params[:locale]
    locale ||= locale_from_account(@account)
    locale ||= locale_from_accept_language
    set_locale(locale, &)
  end

  def locale_from_accept_language
    return nil unless request.headers['Accept-Language']

    find_matching_locale(parse_accept_language_header)
  end

  def parse_accept_language_header
    parsed = request.headers['Accept-Language'].split(',').map do |lang|
      parts = lang.strip.split(';')
      code = parts[0].tr('-', '_')
      quality = extract_quality(parts[1])
      [code, quality]
    end
    parsed.sort_by { |_, q| -q }
  end

  def extract_quality(quality_part)
    quality_part&.match(/q=(.+)/)&.captures&.first&.to_f || 1.0
  end

  def find_matching_locale(accepted_locales)
    available = I18n.available_locales.map(&:to_s)

    accepted_locales.each do |locale_pair|
      code = locale_pair.first
      return code if available.include?(code)

      base = code.split('_').first
      return base if available.include?(base)
    end

    nil
  end
end
