require 'rails_helper'

# A validation message translated when the class body ran stays in that moment's locale (and, in
# production, says "Translation missing"). These follow the request's locale.
RSpec.describe ApplicationRecord do
  let(:account) { create(:account) }

  def message_for(record, attribute)
    I18n.with_locale(:pt_BR) do
      record.valid?
      record.errors.where(attribute).first&.message
    end
  end

  it 'translates the contact email and phone format errors per request' do
    contact = build(:contact, account: account, email: 'not-an-email', phone_number: '123')

    expect(message_for(contact, :email)).to eq(I18n.t('errors.contacts.email.invalid', locale: :pt_BR))
    expect(message_for(contact, :phone_number)).to eq(I18n.t('errors.contacts.phone_number.invalid', locale: :pt_BR))
  end

  it 'translates the company domain format error per request' do
    company = build(:company, account: account, domain: 'not a domain')

    expect(message_for(company, :domain)).to eq(I18n.t('errors.companies.domain.invalid', locale: :pt_BR))
  end

  it 'translates the custom attribute key format error per request' do
    definition = build(:custom_attribute_definition, account: account, attribute_key: 'has space')

    expect(message_for(definition, :attribute_key)).to eq(I18n.t('errors.custom_attribute_definition.attribute_key_format', locale: :pt_BR))
  end

  it 'translates the label and team presence errors per request' do
    expect(message_for(build(:label, account: account, title: ''), :title)).to eq(I18n.t('errors.validations.presence', locale: :pt_BR))
    expect(message_for(build(:team, account: account, name: ''), :name)).to eq(I18n.t('errors.validations.presence', locale: :pt_BR))
  end

  it 'translates the data import type error per request' do
    data_import = build(:data_import, account: account, data_type: 'unknown')

    expect(message_for(data_import, :data_type)).to eq(I18n.t('errors.data_import.data_type.invalid', locale: :pt_BR))
  end

  it 'translates the category locale uniqueness error per request' do
    category = create(:category, account: account)
    duplicate = build(:category, account: account, portal: category.portal, slug: category.slug, locale: category.locale)

    expect(message_for(duplicate, :locale)).to eq(I18n.t('errors.categories.locale.unique', locale: :pt_BR))
  end
end
