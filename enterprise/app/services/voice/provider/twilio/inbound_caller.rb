class Voice::Provider::Twilio::InboundCaller
  WITHHELD_NUMBERS = %w[266696687 86282452253 8656696 2562533 7378742833 464].freeze

  pattr_initialize [:from!, :call_sid!, :account!]

  def build
    if from.match?(/\A\+[1-9]\d{1,14}\z/) && WITHHELD_NUMBERS.exclude?(from.delete_prefix('+'))
      return { source_ids: [from], contact_attributes: { name: from, phone_number: from } }
    end

    {
      source_ids: ["anonymous:#{call_sid}"],
      contact_attributes: { name: I18n.t('conversations.messages.voice_call.unknown_caller', locale: account.locale) }
    }
  end
end
