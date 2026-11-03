# The contact filter fields Jev may recommend, each with the account's real values as options.
# Country is left out because its roughly 250 options exceed MAX_OPTIONS.
# Text field operators follow what the contact filter form offers for each field.
class Captain::ContactFilterFields
  include Captain::FilterFieldBuilder

  SUBJECT = 'contacts'.freeze
  BLOCKED_OPTIONS = [%w[true Blocked], ['false', 'Not blocked']].freeze

  pattr_initialize [:account!, :user!]

  def subject
    SUBJECT
  end

  def all
    (standard_fields + text_fields + list_attribute_fields(:contact_attribute)).first(MAX_FIELDS)
  end

  private

  # Contacts::FilterService reads only the first value of a condition, so labels take one value here.
  def standard_fields
    [
      field('labels', 'Label', EQUALITY_OPERATORS, options(account.labels, :title, :title)),
      field('blocked', 'Blocked', ['equal_to'], BLOCKED_OPTIONS),
      date_field('created_at', 'Created date'),
      date_field('last_activity_at', 'Last activity date')
    ]
  end

  def text_fields
    [
      text_field('name', 'Name', EQUALITY_OPERATORS),
      text_field('email', 'Email', CONTAINMENT_OPERATORS),
      text_field('phone_number', 'Phone number', CONTAINMENT_OPERATORS),
      # "Identifier" alone matched any ID-like text, such as a phone prefix or a domain.
      text_field('identifier', 'External identifier, an ID from another system', EQUALITY_OPERATORS),
      text_field('city', 'City', CONTAINMENT_OPERATORS),
      text_field('company_name', 'Company', CONTAINMENT_OPERATORS)
    ]
  end
end
