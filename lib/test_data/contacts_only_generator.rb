class TestData::ContactsOnlyGenerator
  def initialize(account:, total_contacts:)
    @account = account
    @total_contacts = total_contacts
    @batch_size = TestData::Constants::BATCH_SIZE
  end

  def generate!
    Rails.logger.info { "Starting contact generation for account ##{@account.id}" }
    contact_count = 0
    batch_number = 0

    while contact_count < @total_contacts
      batch_number += 1
      current_batch_size = [@batch_size, @total_contacts - contact_count].min
      Rails.logger.info { "Processing batch ##{batch_number} (#{current_batch_size} contacts) for account ##{@account.id}" }
      create_contact_batch(current_batch_size)
      contact_count += current_batch_size
    end

    Rails.logger.info { "==> Completed #{contact_count} contacts for account ##{@account.id}" }
  end

  private

  # rubocop:disable Rails/SkipsModelValidations
  def create_contact_batch(batch_size)
    contacts_data = Array.new(batch_size) { build_contact_data }
    Contact.insert_all!(contacts_data) if contacts_data.any?
  end
  # rubocop:enable Rails/SkipsModelValidations

  def build_contact_data
    created_at = Faker::Time.between(from: 1.year.ago, to: Time.current)
    email_type = determine_email_type

    # Generate name components for consistency
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name

    {
      account_id: @account.id,
      name: "#{first_name} #{last_name}",
      email: generate_email(email_type, first_name, last_name),
      phone_number: generate_phone_number,
      additional_attributes: generate_additional_attributes(email_type),
      created_at: created_at,
      updated_at: created_at
    }
  end

  def determine_email_type
    rand_value = rand(1..100)
    if rand_value <= TestData::Constants::CONTACTS_WITH_COMPANY_NAME_PCT
      :with_company_name
    elsif rand_value <= (TestData::Constants::CONTACTS_WITH_COMPANY_NAME_PCT + TestData::Constants::CONTACTS_BUSINESS_ONLY_PCT)
      :business_only
    else
      :free_email
    end
  end

  def generate_email(email_type, first_name, last_name)
    case email_type
    when :with_company_name, :business_only
      generate_business_email(first_name, last_name)
    when :free_email
      generate_free_email(first_name, last_name)
    end
  end

  def generate_business_email(first_name, last_name)
    first = first_name.downcase.gsub(/[^a-z]/, '')
    last = last_name.downcase.gsub(/[^a-z]/, '')
    domain = TestData::Constants::BUSINESS_DOMAINS.sample
    "#{first}.#{last}@#{domain}"
  end

  def generate_free_email(first_name, last_name)
    first = first_name.downcase.gsub(/[^a-z]/, '')
    last = last_name.downcase.gsub(/[^a-z]/, '')
    provider = (TestData::Constants::FREE_EMAIL_PROVIDERS + TestData::Constants::DISPOSABLE_EMAIL_PROVIDERS).sample
    "#{first}.#{last}#{rand(1000)}@#{provider}"
  end

  def generate_phone_number
    return nil unless rand < 0.7

    country_code = TestData::Constants::COUNTRY_CODES.sample
    subscriber_number = rand(1_000_000..9_999_999_999).to_s
    subscriber_number = subscriber_number[0...(15 - country_code.length)]
    "+#{country_code}#{subscriber_number}"
  end

  def generate_additional_attributes(email_type)
    # Always create attributes if we need company_name
    if email_type == :with_company_name
      return {
        company_name: Faker::Company.name,
        city: Faker::Address.city,
        country: Faker::Address.country_code
      }
    end

    # For other types, 50% chance of having city/country
    return nil unless rand < 0.5

    {
      city: Faker::Address.city,
      country: Faker::Address.country_code
    }
  end
end
