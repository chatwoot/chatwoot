class JsonbAttributesLengthValidator < ActiveModel::EachValidator
  MAX_STRING_LENGTH = 1500

  # `mail_subject` carries whatever the sender typed into the Subject field, and people do write
  # a whole request in there: phone mail clients put the cursor in the subject and some customers
  # never move it to the body. Holding that to the generic limit made the conversation invalid,
  # and the IMAP mailbox then dropped the email without a trace, because the raise happens inside
  # per-message processing and the fetcher just skips the UID. Measured in production on
  # 22/Sep/2026: one subject of 1972 characters, unseen for 21 hours.
  #
  # Still bounded, and deliberately so. `additional_attributes` rides in every conversation
  # payload over ActionCable and webhooks, so an unbounded subject would be paid for on every
  # event of that conversation, forever, by every subscriber.
  #
  # Nothing is cut on the way out. RFC 5322 bounds a physical line, not a subject, and Mail folds
  # an unstructured header at whitespace, so prose of any length leaves as legal lines. Cutting
  # the value at send time instead would change the normalized subject that Gmail and Outlook
  # thread on, and would split the thread of every conversation already holding a subject past
  # the cut, which the generic limit has always allowed up to 1500.
  #
  # Keyed by attribute as well as by key, because the same validator also guards
  # `custom_attributes`, whose keys are whatever an operator typed into the UI. Without the
  # attribute, an account that happens to define a custom attribute named `mail_subject` would
  # silently inherit the allowance meant for the mailbox.
  KEY_MAX_STRING_LENGTH = {
    additional_attributes: { 'mail_subject' => 8_000 }
  }.freeze

  def validate_each(record, attribute, value)
    return if value.empty?

    @attribute = attribute
    @record = record

    value.each do |key, attribute_value|
      validate_keys(key, attribute_value)
    end
  end

  def validate_keys(key, attribute_value)
    case attribute_value.class.name
    when 'String'
      max = max_string_length(key)
      @record.errors.add @attribute, "#{key} length should be < #{max}" if attribute_value.length > max
    when 'Integer'
      @record.errors.add @attribute, "#{key} value should be < 9999999999" if attribute_value > 9_999_999_999
    end
  end

  private

  def max_string_length(key)
    KEY_MAX_STRING_LENGTH.dig(@attribute.to_sym, key.to_s) || MAX_STRING_LENGTH
  end
end
