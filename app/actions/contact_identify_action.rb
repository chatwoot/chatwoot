# retain_original_contact_name: false / true
# In case of setUser we want to update the name of the identified contact,
# which is the default behaviour
#
# But, In case of contact merge during prechat form contact update.
# We don't want to update the name of the identified original contact.

class ContactIdentifyAction
  include UrlHelper
  # contact_inbox is the session that sent the request. Its inbox decides whether details alone can merge contacts.
  # verification_source names the trusted source the params come from, such as a signed token. Without it they are visitor input.
  pattr_initialize [:contact!, :params!, :contact_inbox!,
                    { retain_original_contact_name: false, discard_invalid_attrs: false, verification_source: nil }]

  def perform
    @attributes_to_update = [:identifier, :name, :email, :phone_number]

    ActiveRecord::Base.transaction do
      merge_if_existing_identified_contact
      merge_if_existing_email_contact
      merge_if_existing_phone_number_contact
      update_contact
    end
    @contact
  end

  private

  def account
    @account ||= @contact.account
  end

  def merge_if_existing_identified_contact
    return unless merge_contacts?(existing_identified_contact, :identifier)

    process_contact_merge(existing_identified_contact)
  end

  def merge_if_existing_email_contact
    return unless merge_contacts?(existing_email_contact, :email)

    process_contact_merge(existing_email_contact)
  end

  def merge_if_existing_phone_number_contact
    return unless merge_contacts?(existing_phone_number_contact, :phone_number)
    return unless mergable_phone_contact?

    process_contact_merge(existing_phone_number_contact)
  end

  def process_contact_merge(mergee_contact)
    @contact = merge_contact(mergee_contact, @contact)
    @attributes_to_update.delete(:name) if retain_original_contact_name
  end

  def existing_identified_contact
    return if params[:identifier].blank?

    @existing_identified_contact ||= account.contacts.find_by(identifier: params[:identifier])
  end

  def existing_email_contact
    return if params[:email].blank?

    @existing_email_contact ||= account.contacts.from_email(params[:email])
  end

  def existing_phone_number_contact
    return if params[:phone_number].blank?

    @existing_phone_number_contact ||= account.contacts.find_by(phone_number: params[:phone_number])
  end

  def merge_contacts?(existing_contact, key)
    return if existing_contact.blank?
    # A visitor cannot change a verified value, so the contact cannot join another one through it.
    # The contact can change after each merge, so this asks the current one.
    return false if protected_from_visitor?(key)

    return true if params[:identifier].blank? && anonymous_widget_visitor_on_open_inbox?
    return true unless identified_as_someone_else?(existing_contact)

    # we want to prevent merging contacts with different identifiers
    # we will remove attribute from update list
    @attributes_to_update.delete(key) unless take_value_from?(existing_contact, key)
    false
  end

  def visitor_input?
    verification_source.blank?
  end

  # The identifier is what a contact's values were verified for. A visitor who could change it
  # would keep those values under an identifier of their choice, and lock their owner out of them.
  def protected_from_visitor?(attribute)
    return false unless visitor_input?
    return @contact.any_attribute_verified? if attribute.to_sym == :identifier

    @contact.attribute_verified?(attribute)
  end

  def identified_as_someone_else?(existing_contact)
    existing_contact.identifier.present? && existing_contact.identifier != params[:identifier]
  end

  # A value from a trusted source moves from another identified contact to this one, unless that contact's value is verified too.
  def take_value_from?(identified_contact, key)
    return false if visitor_input?

    if identified_contact.attribute_verified?(key)
      Rails.logger.info "[CONTACT_IDENTIFY] Skipped verified #{key} of contact #{@contact.id}: " \
                        "contact #{identified_contact.id} holds it as verified in account #{account.id}"
      return false
    end

    identified_contact.update!(key => nil)
    Rails.logger.info "[CONTACT_IDENTIFY] Moved #{key} from contact #{identified_contact.id} to contact #{@contact.id} " \
                      "in account #{account.id}"
    true
  end

  # An anonymous widget visitor can join an identified contact by entering its email or phone number.
  # A contact that already has an identifier never joins a different one, and inboxes that require
  # identity validation keep visitors apart until they pass it. A verified session never joins this way,
  # because it would carry its verified flag to the matched contact. Client API responses return the
  # contact's details to the session, so API inboxes never join an identified contact this way.
  def anonymous_widget_visitor_on_open_inbox?
    return false if contact_inbox.hmac_verified?

    @contact.identifier.blank? && contact_inbox.inbox.web_widget? && !contact_inbox.inbox.channel.hmac_mandatory
  end

  # case: contact 1: email: 1@test.com, phone: 123456789
  # params: email: 2@test.com, phone: 123456789
  # we don't want to overwrite 1@test.com since email parameter takes higer priority
  #
  # A phone number from a trusted source follows the same rule. The other contact may be a real WhatsApp or SMS contact,
  # and channels do not mark the phone numbers they supply as verified yet. Until they do, the number stays with that contact.
  def mergable_phone_contact?
    return true if params[:email].blank?

    if existing_phone_number_contact.email.present? && existing_phone_number_contact.email != params[:email]
      log_skipped_phone_number unless visitor_input?
      @attributes_to_update.delete(:phone_number)
      return false
    end
    true
  end

  # A visitor cannot change a verified value. The contact can be another one after a merge,
  # so this reads the marks of the contact that is written.
  def writable_params
    params.reject { |attribute, _value| protected_from_visitor?(attribute) }
  end

  def log_skipped_phone_number
    Rails.logger.info "[CONTACT_IDENTIFY] Skipped verified phone_number of contact #{@contact.id}: " \
                      "contact #{existing_phone_number_contact.id} holds it with another email in account #{account.id}"
  end

  def update_contact
    # blank identifier or email will throw unique index error
    # TODO: replace reject { |_k, v| v.blank? } with compact_blank when rails is upgraded
    assign_contact_values(writable_params.slice(*@attributes_to_update).reject { |_k, v| v.blank? })
    @contact.attributes = { custom_attributes: custom_attributes, additional_attributes: additional_attributes }
    @contact.discard_invalid_attrs if discard_invalid_attrs
    # A trusted value that the contact already stores changes no column, but its mark still has to be stored.
    @contact.save! if @contact.changed? || @contact.verification_to_store?
    enqueue_avatar_job
  end

  def assign_contact_values(values)
    return @contact.attributes = values if visitor_input?

    @contact.attributes = values.slice(:identifier)
    @contact.assign_verified_attributes(values.except(:identifier), source: verification_source)
  end

  def enqueue_avatar_job
    return unless params[:avatar_url].present? && !@contact.avatar.attached?
    return unless url_valid?(params[:avatar_url])

    Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url])
  end

  def merge_contact(base_contact, merge_contact)
    return base_contact if base_contact.id == merge_contact.id

    Rails.logger.info "[CONTACT_IDENTIFY] Merging contact #{merge_contact.id} into contact #{base_contact.id} in account #{account.id}"
    ContactMergeAction.new(
      account: account,
      base_contact: base_contact,
      mergee_contact: merge_contact
    ).perform
  end

  def custom_attributes
    return @contact.custom_attributes if params[:custom_attributes].blank?

    (@contact.custom_attributes || {}).deep_merge(params[:custom_attributes].stringify_keys)
  end

  def additional_attributes
    return @contact.additional_attributes if params[:additional_attributes].blank?

    (@contact.additional_attributes || {}).deep_merge(params[:additional_attributes].stringify_keys)
  end
end
