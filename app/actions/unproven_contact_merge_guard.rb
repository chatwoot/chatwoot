# A visitor on a public channel can type an email or a phone number, and upstream joins the session
# to whichever contact of the account already holds that value: ContactIdentifyAction merges into
# it, and ContactInboxWithContactBuilder hands a brand-new public API session that contact outright.
# Nothing in those requests proves the visitor is that person, so typing a customer's phone number
# was enough to become the customer: the session lands on their contact, an agent bot's HTTP tools
# get their contact_id and phone, and the human agent reads the visitor's messages under the
# customer's name. Upstream closed the case where the existing contact carries an identifier
# (chatwoot/chatwoot#14935); a contact that came in through an API inbox carries none.
#
# Inside those requests a value that already belongs to another contact is therefore not used to
# find or merge one. It stays on the visitor as an unverified claim in additional_attributes
# (`claimed_email`, `claimed_phone_number`), which the contact panel shows so an agent can confirm
# it or merge the contacts by hand. When the value belongs to another contact, it is also handed to
# upstream's unverified matches, so the conversation gets upstream's private note pointing the agent
# at that contact (Conversations::UnverifiedContactNoteService).
#
# A phone number is held back as a claim even when nobody holds it yet. Saved on the contact it is
# the visitor's verified phone to everything downstream: an agent bot's tools get it as
# contact_phone, and whatever an outside system keeps for that number with it, and the real owner
# writing in later through WhatsApp is found by it and lands on the visitor's contact. An email
# nobody holds is still saved, because the reply-by-email of a widget conversation needs it and
# nothing downstream treats it as a credential.
#
# The visitor's own additional_attributes cannot carry the keys the system writes there: the claims
# above and the CRM lead ids under `external`.
#
# Identifiers in WhatsApp's format ("<lid>@lid", phone and group JIDs) are refused outright: the
# fork's WhatsApp providers store them as contact identifiers, so an unsigned setUser with
# someone's LID would reach their WhatsApp contact, and no site identifies its users that way.
#
# That holds with a valid identifier_hash too: the site signs the identifier and nothing else, so a
# signed-in visitor could otherwise send their own identifier and hash next to someone else's phone.
# The identifier keeps finding and merging its contact as upstream does, signed or, where the inbox
# leaves HMAC optional, unsigned (upstream's contract for setUser without identity validation).
#
# Module prepends rather than edits to upstream files, so an upstream sync never conflicts here
# (config/initializers/unproven_contact_merge_guard.rb).
module UnprovenContactMergeGuard
  CLAIM_PREFIX = 'claimed_'.freeze
  # Contact's own phone_number format: anything else is not a phone number to claim.
  PHONE_NUMBER_FORMAT = /\A\+[1-9]\d{1,14}\z/
  WHATSAPP_IDENTIFIER_FORMAT = /@(lid|s\.whatsapp\.net|c\.us|g\.us)\z/

  class Context < ActiveSupport::CurrentAttributes
    attribute :unproven
  end

  def self.unproven(&)
    Context.set(unproven: true, &)
  end

  def self.unproven?
    Context.unproven == true
  end

  def self.claimable_phone_number?(value)
    value.to_s.match?(PHONE_NUMBER_FORMAT)
  end

  def self.system_attribute?(key)
    key.to_s.start_with?(CLAIM_PREFIX) || key.to_s == 'external'
  end

  def self.whatsapp_identifier?(value)
    value.to_s.match?(WHATSAPP_IDENTIFIER_FORMAT)
  end

  module IdentifyAction
    # The widget's contact update takes additional_attributes as the visitor sends them. Two keys there
    # are the system's, not the visitor's: the claims this guard records (the panel shows them as typed
    # by the visitor) and `external`, the CRM lead ids the CRM sync reads to decide which lead to write.
    def perform
      submitted = params[:additional_attributes]
      if UnprovenContactMergeGuard.unproven? && submitted.present?
        @params = params.merge(additional_attributes: submitted.reject { |key, _| UnprovenContactMergeGuard.system_attribute?(key) })
      end
      super
    end

    private

    def merge_if_existing_email_contact
      return super unless UnprovenContactMergeGuard.unproven? && someone_else?(existing_email_contact)

      record_unverified_match(:email, existing_email_contact)
      hold_back_claim(:email)
    end

    def merge_if_existing_phone_number_contact
      return super unless UnprovenContactMergeGuard.unproven?

      phone_number = params[:phone_number]
      return if phone_number.blank? || phone_number == @contact.phone_number

      # A value that is not a phone number is left to upstream, which discards or rejects it.
      return unless UnprovenContactMergeGuard.claimable_phone_number?(phone_number)

      record_unverified_match(:phone_number, existing_phone_number_contact) if someone_else?(existing_phone_number_contact)
      hold_back_claim(:phone_number)
    end

    def someone_else?(existing_contact)
      existing_contact.present? && existing_contact.id != @contact.id
    end

    def record_unverified_match(key, existing_contact)
      @unverified_matches << { key: key, value: params[key], contact: existing_contact }
    end

    def hold_back_claim(key)
      @attributes_to_update.delete(key)
      (@held_back_claims ||= {})["#{CLAIM_PREFIX}#{key}"] = params[key]
    end

    def additional_attributes
      return super if @held_back_claims.blank?

      (super || {}).merge(@held_back_claims)
    end
  end

  module ContactBuilder
    private

    # Only the identifier finds an existing contact here, under the caller's HMAC rules.
    def find_contact
      return super unless UnprovenContactMergeGuard.unproven?

      find_contact_by_identifier(contact_attributes[:identifier])
    end

    def create_contact
      return super unless UnprovenContactMergeGuard.unproven?

      held_back = held_back_details
      return super if held_back.empty?

      claims = held_back.to_h { |key| ["#{CLAIM_PREFIX}#{key}", contact_attributes[key]] }
      @contact_attributes = contact_attributes.merge(held_back.index_with(nil)).merge(
        additional_attributes: (contact_attributes[:additional_attributes] || {}).to_h.merge(claims)
      )
      super
    end

    def held_back_details
      held_back = []
      held_back << :email if find_contact_by_email(contact_attributes[:email])
      held_back << :phone_number if UnprovenContactMergeGuard.claimable_phone_number?(contact_attributes[:phone_number])
      held_back
    end
  end

  module RefusesWhatsappIdentifier
    private

    def whatsapp_identifier_refused?
      return false unless UnprovenContactMergeGuard.whatsapp_identifier?(params[:identifier])

      render json: { error: 'This identifier is reserved for WhatsApp contacts' }, status: :unprocessable_entity
      true
    end
  end

  module WidgetContacts
    include RefusesWhatsappIdentifier

    def update
      return if whatsapp_identifier_refused?

      UnprovenContactMergeGuard.unproven { super }
    end

    def set_user
      return if whatsapp_identifier_refused?

      UnprovenContactMergeGuard.unproven { super }
    end
  end

  module WidgetConversations
    def process_update_contact
      UnprovenContactMergeGuard.unproven { super }
    end
  end

  module WidgetMessages
    def update
      UnprovenContactMergeGuard.unproven { super }
    end
  end

  module PublicContacts
    include RefusesWhatsappIdentifier

    def create
      return if whatsapp_identifier_refused?

      UnprovenContactMergeGuard.unproven { super }
    end

    def update
      UnprovenContactMergeGuard.unproven { super }
    end

    private

    # Upstream raises a bare StandardError for a missing or wrong hash, which reaches the client as a 500.
    def process_hmac
      super
    rescue StandardError => e
      raise unless e.message.start_with?('HMAC failed')

      render json: { error: e.message }, status: :unauthorized
    end
  end

  # The email collect card asks a visitor whose contact has no email. One whose email was held back
  # as a claim already answered, and asking again would only collect the same claim.
  module EmailCollect
    private

    def contact_has_email?
      super || contact.additional_attributes&.dig("#{CLAIM_PREFIX}email").present?
    end
  end
end
