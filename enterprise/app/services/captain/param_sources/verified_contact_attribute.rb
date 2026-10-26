# A business managed attribute of the contact the customer proved they are. Customers cannot write these attributes.
class Captain::ParamSources::VerifiedContactAttribute
  PREFIX = 'verified.contact.attributes.'.freeze
  MESSAGES = {
    unverified: 'This tool needs to know who the customer is, and they have not verified it yet. ' \
                'Verify their email with a one-time code first, then call this tool again. ' \
                'If that is not possible, ask whether they want to talk to a support agent.',
    mismatch: 'The ways this customer verified who they are point to different accounts, so this tool cannot run. ' \
              'Tell the customer that something does not match on their account, and ask whether they want to talk to a support agent.',
    not_found: 'No account matches the email this customer verified, so this tool cannot run. ' \
               'Tell the customer you could not find their account, and ask whether they want to talk to a support agent.',
    missing_value: 'The customer\'s account is missing a detail this tool needs, so it cannot run. ' \
                   'Tell the customer you could not look this up, and ask whether they want to talk to a support agent.',
    not_business_managed: 'This tool is not set up correctly, so it cannot run. Ask whether the customer wants to talk to a support agent.'
  }.freeze

  def self.parse(name)
    new(name.delete_prefix(PREFIX)) if name.start_with?(PREFIX) && name.length > PREFIX.length
  end

  def initialize(key)
    @key = key
  end

  def validate(account)
    I18n.t('captain.custom_tool.param_sources.not_business_managed', key: @key) unless business_managed?(account)
  end

  # Checked on every call, so an attribute that stops being business managed stops filling tools
  def resolve(conversation)
    unavailable!(:not_business_managed) unless conversation && business_managed?(conversation.account)

    verified_contact = Captain::VerifiedContact.new(conversation)
    unavailable!(verified_contact.status) unless verified_contact.contact

    verified_contact.contact.custom_attributes[@key].presence&.to_s || unavailable!(:missing_value)
  end

  private

  def business_managed?(account)
    account.custom_attribute_definitions.business_managed.exists?(attribute_key: @key)
  end

  def unavailable!(reason)
    raise Captain::ParamSources::Unavailable, MESSAGES.fetch(reason)
  end
end
