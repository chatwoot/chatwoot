# retain_original_contact_name: false / true
# In case of setUser we want to update the name of the identified contact,
# which is the default behaviour
#
# But, In case of contact merge during prechat form contact update.
# We don't want to update the name of the identified original contact.
#
# contact_inbox: the widget session that sent the request.
# An unverified session can link to a contact with a verified session by email or phone, but can't change that contact.

class ContactIdentifyAction
  include UrlHelper
  pattr_initialize [:contact!, :params!, { contact_inbox: nil, retain_original_contact_name: false, discard_invalid_attrs: false }]

  def perform
    @attributes_to_update = [:identifier, :name, :email, :phone_number]

    ActiveRecord::Base.transaction do
      merge_if_existing_identified_contact
      merge_if_existing_email_contact
      merge_if_existing_phone_number_contact
      update_contact unless unverified_session_on?(@contact)
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
    return true if mergeable?(existing_contact, key)

    # we will remove attribute from update list
    @attributes_to_update.delete(key)
    false
  end

  def mergeable?(existing_contact, key)
    # An unverified session never moves a contact with a verified session
    return false if unverified_session_on?(@contact)

    # Never merge into a contact that already owns an identifier unless the request
    # supplies the matching one. This also covers the blank-identifier case: an
    # unverified/anonymous request must not take over an identified contact just by
    # matching its email or phone_number. Merges into non-identified contacts
    # (anonymous dedup) are still allowed.
    return true if existing_contact.identifier.blank? || existing_contact.identifier == params[:identifier]

    # An unverified widget session links to a contact with a verified session by email or phone, and stays unverified
    key != :identifier && unverified_session_on?(existing_contact) && session_only_contact?
  end

  # Only a contact that holds nothing but this session moves, so linking never carries other history with it
  def session_only_contact?
    @contact.identifier.blank? && @contact.contact_inboxes.one?
  end

  def unverified_session_on?(contact)
    contact_inbox.present? && !contact_inbox.hmac_verified? && contact.verified_session?
  end

  # case: contact 1: email: 1@test.com, phone: 123456789
  # params: email: 2@test.com, phone: 123456789
  # we don't want to overwrite 1@test.com since email parameter takes higer priority
  def mergable_phone_contact?
    return true if params[:email].blank?

    if existing_phone_number_contact.email.present? && existing_phone_number_contact.email != params[:email]
      @attributes_to_update.delete(:phone_number)
      return false
    end
    true
  end

  def update_contact
    @contact.attributes = params.slice(*@attributes_to_update).reject do |_k, v|
      v.blank?
    end.merge({ custom_attributes: custom_attributes, additional_attributes: additional_attributes })
    # blank identifier or email will throw unique index error
    # TODO: replace reject { |_k, v| v.blank? } with compact_blank when rails is upgraded
    @contact.discard_invalid_attrs if discard_invalid_attrs
    @contact.save! if @contact.changed?
    enqueue_avatar_job
  end

  def enqueue_avatar_job
    return unless params[:avatar_url].present? && !@contact.avatar.attached?
    return unless url_valid?(params[:avatar_url])

    Avatar::AvatarFromUrlJob.perform_later(@contact, params[:avatar_url])
  end

  def merge_contact(base_contact, merge_contact)
    return base_contact if base_contact.id == merge_contact.id

    ContactMergeAction.new(
      account: account,
      base_contact: base_contact,
      mergee_contact: merge_contact,
      keep_base_attributes: unverified_session_on?(base_contact)
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
