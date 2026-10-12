class SalesRouting::Classifier
  STORE_CODE = /\[(PSD|LAP|TAT)\]/i
  CAMPAIGN_STORES = { 'psd' => /\b(?:PSD|SAO DOMINGOS)\b/, 'lap' => /\b(?:LAPA|LAP)\b/, 'tat' => /\b(?:TATUAPE|TAT)\b/ }.freeze
  ATTRIBUTES_KEY = 'store_routing'.freeze
  ENRICHMENT_WAIT = 5.seconds

  pattr_initialize [:conversation!]

  def perform
    return true if conversation.additional_attributes[ATTRIBUTES_KEY].present?
    return false unless first_message
    return defer_classification if Time.current < first_message.created_at + ENRICHMENT_WAIT

    store, rule, previous_agent_id = resolve_store
    route = { 'store' => store, 'rule' => rule, 'origin' => origin, 'campaign' => campaign,
              'preferred_agent_id' => previous_agent_id, 'first_customer_message_at' => first_message.created_at.iso8601(6),
              'outside_business_hours' => outside_business_hours? }
    save_classification(route)
    true
  end

  private

  def save_classification(route)
    store = route['store']
    conversation.additional_attributes[ATTRIBUTES_KEY] = route
    conversation.label_list.add(store ? configuration.stores.fetch(store).fetch('label') : 'loja-indefinida', "origem-#{origin}")
    conversation.custom_attributes['campanha'] = campaign if campaign.present?
    # Existing manual ownership/team choices take precedence over automatic routing.
    assign_initial_team(store)
    conversation.save!
  end

  def assign_initial_team(store)
    return unless store && conversation.assignee_id.nil? && conversation.team_id.nil?

    conversation.team = configuration.team_for(store)
  end

  def defer_classification
    SalesRouting::ClassifyJob.set(wait_until: first_message.created_at + ENRICHMENT_WAIT).perform_later(conversation.id)
    false
  end

  def configuration
    @configuration ||= SalesRouting::Configuration.new(inbox: conversation.inbox)
  end

  def first_message
    @first_message ||= conversation.messages.incoming.where(private: false).order(:created_at, :id).first
  end

  def text
    first_message.content.to_s
  end

  def campaign
    text[/\bref:\s*([^\r\n]+)/i, 1]&.strip
  end

  def outside_business_hours?
    inbox = conversation.inbox
    return false unless inbox.working_hours_enabled?

    time = first_message.created_at.in_time_zone(inbox.timezone)
    hours = inbox.working_hours.find_by!(day_of_week: time.wday)
    return true if hours.closed_all_day?
    return false if hours.open_all_day?

    minutes = (time.hour * 60) + time.min
    minutes < (hours.open_hour * 60) + hours.open_minutes || minutes >= (hours.close_hour * 60) + hours.close_minutes
  end

  def referral
    @referral ||= ConversationAdReferral.find_by(conversation_id: conversation.id)
  end

  def origin
    return 'google' if text.match?(/vim do google/i)
    return 'meta' if referral.present? || first_message.content_attributes['referral'].present?
    return 'site' if campaign.present? || text.match?(/tenho interesse neste produto/i)

    'direto'
  end

  def resolve_store
    code = text[STORE_CODE, 1]&.downcase
    return [code, 'codigo', nil] if code

    code = campaign_store
    return [code, 'campanha-meta', nil] if code

    previous = previous_conversation
    return [previous_store(previous), 'cliente-voltou', previous.assignee_id] if previous

    [nil, 'sem-sinal', nil]
  end

  def campaign_store
    ad = referral&.meta_ad
    campaign_text = ActiveSupport::Inflector.transliterate([ad&.campaign_name, ad&.adset_name].compact.join(' ')).upcase
    CAMPAIGN_STORES.find { |_store, pattern| campaign_text.match?(pattern) }&.first
  end

  def previous_conversation
    return if conversation.contact.phone_number.blank?

    contacts = Contact.where(account_id: conversation.account_id, phone_number: conversation.contact.phone_number).select(:id)
    history = Conversation.where(account_id: conversation.account_id, contact_id: contacts).where.not(id: conversation.id)
    history.where('last_activity_at >= ?', 60.days.ago).order(last_activity_at: :desc, id: :desc)
           .detect { |previous| previous_store(previous).present? }
  end

  def previous_store(previous)
    code = previous.additional_attributes.dig(ATTRIBUTES_KEY, 'store') || configuration.store_for_team(previous.team_id)
    code if configuration.stores.key?(code)
  end
end
