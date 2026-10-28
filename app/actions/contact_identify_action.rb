# retain_original_contact_name: false / true
# In case of setUser we want to update the name of the identified contact,
# which is the default behaviour
#
# But, In case of contact merge during prechat form contact update.
# We don't want to update the name of the identified original contact.

class ContactIdentifyAction
  include UrlHelper
  pattr_initialize [:contact!, :params!, { retain_original_contact_name: false, discard_invalid_attrs: false }]

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
    # A differing phone number already means these are kept as separate contacts (see
    # mergable_email_contact? below), so an identifier mismatch shouldn't also strip :email
    # from the update list in that case - there's no contact being taken over, so the current
    # contact is still allowed to record its own email alongside its own phone number.
    return unless merge_contacts?(existing_email_contact, :email, strip_on_mismatch: mergable_email_contact?)
    return unless mergable_email_contact?

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

    # Prefer the same-email contact whose phone matches, so a shared email resolves to the right one
    @existing_email_contact ||= account.contacts.from_email_and_phone_number(params[:email], params[:phone_number]) ||
                                account.contacts.from_email(params[:email])
  end

  def existing_phone_number_contact
    return if params[:phone_number].blank?

    @existing_phone_number_contact ||= account.contacts.find_by(phone_number: params[:phone_number])
  end

  def merge_contacts?(existing_contact, key, strip_on_mismatch: true)
    return if existing_contact.blank?

    # Never merge into a contact that already owns an identifier unless the request
    # supplies the matching one. This also covers the blank-identifier case: an
    # unverified/anonymous request must not take over an identified contact just by
    # matching its email or phone_number. Merges into non-identified contacts
    # (anonymous dedup) are still allowed.
    if existing_contact.identifier.present? && existing_contact.identifier != params[:identifier]
      # we will remove attribute from update list, unless the caller already knows this
      # attribute is safe to keep on the current contact regardless (see
      # merge_if_existing_email_contact)
      @attributes_to_update.delete(key) if strip_on_mismatch
      return false
    end

    true
  end

  # case: contact 1: email: a@test.com, phone: 111
  # params: email: a@test.com, phone: 222
  # a different, non-blank phone number submitted alongside an email that already belongs to
  # another contact means this is a different person sharing that email (a shared family or
  # company inbox, say). Keep them as separate contacts instead of merging into contact 1.
  #
  # Falls back to the current contact's own stored phone number when the request doesn't
  # submit one (e.g. the widget's email-collection prompt only sends email+name): a contact
  # that already has a phone number shouldn't lose it to a merge just because this particular
  # request happened not to repeat it.
  #
  # Keeping the visitor separate only works if they can actually keep that phone number. When
  # another contact owns it under a different email, or under an identifier this request doesn't
  # match, the phone path below will drop it, and a phone-less copy of this email can't be saved
  # next to contact 1, so merge into contact 1 as before.
  def mergable_email_contact?
    return true if existing_email_contact.blank?

    phone_number = submitted_phone_number || @contact.phone_number
    return true if phone_number.blank?
    return true if existing_email_contact.phone_number.blank? || existing_email_contact.phone_number == phone_number

    phone_number_unavailable?
  end

  # With discard_invalid_attrs, update_contact drops a malformed phone before saving, so it can't
  # be what tells this visitor apart from the email contact either
  def submitted_phone_number
    phone_number = params[:phone_number].presence
    return phone_number unless discard_invalid_attrs && phone_number

    phone_number if phone_number.match?(Contact::PHONE_NUMBER_FORMAT)
  end

  def phone_number_unavailable?
    owner = existing_phone_number_contact
    return false if owner.blank? || owner.id == @contact.id

    (owner.email.present? && owner.email != params[:email]) ||
      (owner.identifier.present? && owner.identifier != params[:identifier])
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
