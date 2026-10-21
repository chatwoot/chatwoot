class Voice::Provider::Twilio::InboundCaller
  # Twilio can encode withheld caller-ID labels as digits, e.g. ANONYMOUS becomes 266696687.
  # These are caller-ID placeholders, not callable numbers; 464 represents an empty or missing caller ID.
  # https://help.twilio.com/articles/223179988-Why-am-I-getting-calls-from-these-strange-numbers-
  WITHHELD_NUMBERS = %w[266696687 86282452253 8656696 2562533 7378742833 464].freeze

  pattr_initialize [:from!, :call_sid!, :account!]

  def build
    # Match E.164-style numbers: '+' followed by 2-15 digits, with no leading zero (e.g. +14155550101).
    # Exclude Twilio's numeric withheld-ID placeholders even when they match this format.
    if from.match?(/\A\+[1-9]\d{1,14}\z/) && WITHHELD_NUMBERS.exclude?(from.delete_prefix('+'))
      return { source_ids: [from], contact_attributes: { name: from, phone_number: from } }
    end

    {
      source_ids: ["anonymous:#{call_sid}"],
      contact_attributes: { name: I18n.t('conversations.messages.voice_call.unknown_caller', locale: account.locale) }
    }
  end
end
