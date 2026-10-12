class Whatsapp::InteractiveMessages::Eligibility
  TEST_ALLOWLIST_ENV = 'WHATSAPP_TEST_RECIPIENT_ALLOWLIST'.freeze
  E164_PATTERN = /\A\+[1-9]\d{1,14}\z/

  def initialize(conversation)
    @conversation = conversation
  end

  def capabilities
    unavailable_reason = reason
    {
      schema_version: Whatsapp::InteractiveMessages::Registry::SCHEMA_VERSION,
      account_mode: test_mode? ? 'test' : 'production',
      interactive_types: {
        button: {
          implemented: whatsapp_cloud?,
          available: unavailable_reason.nil?,
          unavailable_reason: unavailable_reason,
          limits: Whatsapp::InteractiveMessages::Registry.limits
        }.compact
      }
    }
  end

  def ensure_available!
    unavailable_reason = reason
    raise Whatsapp::InteractiveMessages::EligibilityError, unavailable_reason if unavailable_reason
  end

  def reason
    return 'provider_not_supported' unless whatsapp_cloud?
    return 'service_window_closed' unless @conversation.can_reply?
    return 'test_recipient_not_allowlisted' if test_mode? && !test_recipient_allowlisted?

    nil
  end

  private

  def whatsapp_cloud?
    channel = @conversation.inbox&.channel
    channel.is_a?(Channel::Whatsapp) && channel.provider == 'whatsapp_cloud'
  end

  def test_mode?
    ENV[TEST_ALLOWLIST_ENV].present?
  end

  def test_recipient_allowlisted?
    allowlist.include?(normalized_recipient)
  end

  def allowlist
    ENV.fetch(TEST_ALLOWLIST_ENV, '').split(',').filter_map do |entry|
      candidate = entry.strip
      candidate if candidate.match?(E164_PATTERN)
    end
  end

  def normalized_recipient
    recipient = @conversation.contact_inbox&.source_id.to_s.delete_prefix('whatsapp:')
    recipient = "+#{recipient}" if recipient.match?(/\A[1-9]\d{1,14}\z/)
    recipient if recipient.match?(E164_PATTERN)
  end
end
