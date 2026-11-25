class Whatsapp::WebhookSetupService
  attr_reader :registration_error

  def initialize(channel, waba_id = nil, access_token = nil, is_coexistence: nil, deadline: Whatsapp::GraphDeadline::NONE)
    @channel = channel
    @waba_id = waba_id || channel.provider_config['business_account_id']
    @access_token = access_token || channel.provider_config['api_key']
    @api_client = Whatsapp::FacebookApiClient.new(@access_token, deadline: deadline)
    @is_coexistence = is_coexistence
  end

  def perform
    validate_parameters!

    register_phone_number if should_register_phone_number?

    setup_webhook
  end

  def register_callback
    validate_parameters!
    setup_webhook
  end

  private

  # Coexistence numbers come pre-registered, so /register is redundant. @is_coexistence (from the
  # FE's FINISH event) skips the health API call entirely; the is_on_biz_app fallback only runs for
  # callers that pass no signal at all (nil): manual setup, voice toggle, direct webhook
  # re-registration, since an explicit `false` already means the FE positively ruled out coexistence.
  # Everything else asks the two reads in `registration_needed?`.
  def should_register_phone_number?
    return false if @is_coexistence
    return false if @is_coexistence.nil? && health_data.to_h[:is_on_biz_app]

    registration_needed?
  end

  def validate_parameters!
    raise ArgumentError, 'Channel is required' if @channel.blank?
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
    raise ArgumentError, 'Phone number ID is required' if @channel.provider_config['phone_number_id'].blank?
  end

  def register_phone_number
    phone_number_id = @channel.provider_config['phone_number_id']
    pin = fetch_or_create_pin
    # Stored before the call, not after. The write can time out after Meta already received it, and
    # then the PIN Meta may be holding is the one this attempt drew. Storing it afterwards meant an
    # attempt whose outcome nobody saw left nothing behind, and the next one drew a different PIN,
    # so the app could not name what might already be valid on Meta's side (#590).
    store_pin(pin)

    @api_client.register_phone_number(phone_number_id, pin)
    confirm_pin
  rescue StandardError => e
    # The PIN is never dropped here. A failure establishes nothing about what Meta holds: a 5xx, a
    # rate limit and a body this code could not parse all reach this line, and so does a failure to
    # save the confirmation AFTER a registration Meta accepted. Dropping it on any of those loses a
    # PIN that may well be live and makes the next attempt send a different one, which is the exact
    # disagreement this change exists to prevent.
    #
    # The error is kept for the callers that treat registration as part of their own outcome
    # (manual setup), which raise it once the webhook is in place.
    @registration_error = e
    Rails.logger.warn("[WHATSAPP] Phone registration #{registration_outcome(e)} but continuing " \
                      "(phone_number_id #{phone_number_id}): #{e.message}")
  end

  # A refusal and a silence are different facts and used to share one sentence. Meta answering "no"
  # is something the app knows; a read that never came back is something it does not, and the number
  # may well be registered on Meta's side with the PIN this attempt stored.
  #
  # The boundary is what Meta answered, not the class of the exception, because the class is wrong in
  # both directions. It used to call a `500` a refusal, and an internal error can be raised after the
  # write took effect, so "Meta holds no PIN of ours" is exactly the claim it cannot support. It also
  # called an error of our own a refusal: an answer this code could not parse, and the one raised
  # while storing our own confirmation marker after a registration Meta had accepted, which states
  # the opposite of what happened.
  #
  # So `refused` is reserved for an answer that came back carrying a `4xx`: the request reached Meta
  # and Meta declined it. That includes the `403` for a WABA in another portfolio and the `429` of a
  # rate limit, neither of which is about the PIN, because what the operator acts on is the same
  # fact: Meta answered, and this attempt did not land.
  #
  # Asked of the error's own field and guarded by the class that has the field. A predicate that asks
  # `http_status` of a `Timeout::Error` raises inside the rescue, and then the line that reports the
  # failure becomes the failure.
  def registration_outcome(error)
    return 'refused' if error.is_a?(Whatsapp::ApiError) && error.http_status.to_i.between?(400, 499)

    'outcome unknown'
  end

  def fetch_or_create_pin
    # Check if we have a stored PIN for this phone number
    existing_pin = @channel.provider_config['verification_pin']
    return existing_pin.to_i if existing_pin.present?

    # Generate a new 6-digit PIN if none exists
    SecureRandom.random_number(900_000) + 100_000
  end

  # `save!(validate: false)`, the way every other write to provider_config in this area does it
  # (Channel::Whatsapp#enable_voice_calling! and friends). A plain `save!` runs
  # `validate_provider_config`, which is itself a Graph call, and this one runs on the path where
  # Meta is already misbehaving: a failed re-check would raise, the rescue above would swallow it,
  # and the registration write would never leave. Writing down the PIN we are about to send must
  # not depend on Meta answering a different question first.
  def store_pin(pin)
    @channel.provider_config['verification_pin'] = pin
    @channel.provider_config.delete('verification_pin_confirmed')
    @channel.save!(validate: false)
  end

  # Storing the PIN before the call is what makes a retry send the same one, and it costs the field
  # its old meaning: it used to appear only after Meta answered, so its presence was an answer. Now
  # it says what was sent, and this marker says what came back. The three states the issue is about
  # (#590) are readable again: no PIN means none was ever sent, a confirmed PIN means Meta answered
  # for this one, and an unconfirmed PIN means nobody knows, which is the state that used to be
  # unwritable. Only the middle one is a claim about Meta, and it is only ever written by an answer.
  def confirm_pin
    @channel.provider_config['verification_pin_confirmed'] = true
    @channel.save!(validate: false)
  end

  def setup_webhook
    callback_url = build_callback_url
    verify_token = @channel.provider_config['webhook_verify_token']
    phone_number_id = @channel.provider_config['phone_number_id']

    @api_client.subscribe_phone_number_webhook(@waba_id, phone_number_id, callback_url, verify_token, subscribed_fields: subscribed_fields)
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Webhook setup failed: #{e.message}")
    raise "Webhook setup failed: #{e.message}"
  end

  # Subscribe to `calls` only when voice calling is enabled on the inbox
  def subscribed_fields
    fields = %w[messages smb_message_echoes]
    fields << 'calls' if calls_enabled_on_waba?
    fields
  end

  # `subscribed_fields` is a WABA-wide app subscription, so keep `calls` whenever this inbox or
  # any sibling on the same WABA has voice on: otherwise a non-calling sibling's setup would
  # rewrite the shared subscription and drop calls for a calling-enabled sibling.
  def calls_enabled_on_waba?
    return true if @channel.provider_config['calling_enabled']

    Channel::Whatsapp
      .where(provider: 'whatsapp_cloud')
      .where.not(id: @channel.id)
      .where("provider_config->>'business_account_id' = ?", @waba_id)
      .where("provider_config->>'calling_enabled' = 'true'")
      .exists?
  end

  def build_callback_url
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    phone_number = @channel.phone_number

    "#{frontend_url}/webhooks/whatsapp/#{phone_number}"
  end

  # Registering is a write to Meta plus a PIN on the channel, so it happens on a definite "no" and
  # never on a silence. Both reads below answer three things, not two, and the third one used to be
  # spelled with the same word as "no" (#590).
  #
  # A definite "not verified" registers without consulting the pending state, and anything else asks
  # it, because health names the pending state on its own. "Could not tell" takes the second branch
  # instead of the first.
  def registration_needed?
    return true if verification_state == :not_verified

    pending_state == :pending
  end

  # `:verified`, `:not_verified`, `:unknown`. `:unknown` covers the read that never came back AND
  # the 200 that came back with neither field, which never reached a rescue at all: it used to turn
  # into `false` inside the client, one layer further down than anyone was looking.
  def verification_state
    phone_number_id = @channel.provider_config['phone_number_id']
    status = @api_client.phone_number_verification_status(phone_number_id)

    if status.blank?
      Rails.logger.error("[WHATSAPP] Phone number #{phone_number_id} answered neither status nor code verification status; " \
                         'not deciding registration from it')
      return :unknown
    end

    Rails.logger.info("[WHATSAPP] Phone number #{phone_number_id} status: #{status['status']}, " \
                      "code verification status: #{status['code_verification_status']}")
    # A connected number is already registered even if its one-time code verification has expired.
    # Otherwise, ownership verification is what says it is.
    registered = status['status'] == 'CONNECTED' || status['code_verification_status'] == 'VERIFIED'
    registered ? :verified : :not_verified
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Could not read the code verification status for #{phone_number_id}; " \
                       "not deciding registration from it: #{e.message}")
    :unknown
  end

  # `:pending`, `:not_pending`, `:unknown`. Same vocabulary on purpose: this axis already defaulted
  # the harmless way when it could not tell, and saying so out loud is what keeps the next reader
  # from restoring the other one.
  #
  # `platform_type: NOT_APPLICABLE` means not fully set up, and `throughput.level: NOT_APPLICABLE`
  # means no messaging capacity assigned. Either one is the pending provisioning state.
  def pending_state
    return :unknown if health_data.nil?

    # `:throughput_level`, not `dig(:throughput, :level)`. `throughput` is Meta's object kept
    # verbatim, so its keys are strings and the symbol dig has always answered nil: the throughput
    # half of this check never fired. It did not show because a failed verification read registered
    # the number anyway, and the existing spec stubs the payload with symbol keys, which is not the
    # shape HealthService produces. Now that an unread verification defers to this answer, a number
    # pending only by throughput would have been left unregistered.
    pending = health_data[:platform_type] == 'NOT_APPLICABLE' ||
              health_data[:throughput_level] == 'NOT_APPLICABLE'
    pending ? :pending : :not_pending
  end

  # Read once: `should_register_phone_number?` asks it for the coexistence signal and `pending_state`
  # for the provisioning state. `nil` when the read failed, so each asker can say it could not tell.
  def health_data
    return @health_data if defined?(@health_data)

    @health_data = Whatsapp::HealthService.new(@channel).fetch_health_status
  rescue StandardError => e
    Rails.logger.error("[WHATSAPP] Could not read the health status; not deciding registration from it: #{e.message}")
    @health_data = nil
  end
end
