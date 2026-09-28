require 'rails_helper'

RSpec.describe Captain::CustomerContext do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  def define(model, key, name)
    create(:custom_attribute_definition, account: account, attribute_model: model, attribute_key: key, attribute_display_name: name)
  end

  it 'shares the defined contact and conversation attributes under the names the admin sees' do
    define('contact_attribute', 'plan', 'Plan')
    define('conversation_attribute', 'installation_type', 'Installation Type')
    conversation.contact.update!(custom_attributes: { 'plan' => 'business' })
    conversation.update!(custom_attributes: { 'installation_type' => 'self-hosted' })

    expect(described_class.new(conversation: conversation).attributes).to eq(
      contact: { 'Plan' => 'business' },
      conversation: { 'Installation Type' => 'self-hosted' }
    )
  end

  it 'keeps a false value and leaves out empty ones' do
    define('contact_attribute', 'cloud_customer', 'Cloud customer')
    define('contact_attribute', 'plan', 'Plan')
    conversation.contact.update!(custom_attributes: { 'cloud_customer' => false, 'plan' => '' })

    expect(described_class.new(conversation: conversation).attributes).to eq(contact: { 'Cloud customer' => false }, conversation: {})
  end

  it 'ignores values the account has not defined as custom attributes' do
    conversation.contact.update!(custom_attributes: { 'internal_token' => 'abc123' })

    expect(described_class.new(conversation: conversation).attributes).to eq(contact: {}, conversation: {})
  end

  it 'leaves out an attribute that does not fit the size limit and keeps the rest' do
    define('contact_attribute', 'notes', 'Notes')
    define('contact_attribute', 'plan', 'Plan')
    conversation.contact.update!(custom_attributes: { 'notes' => 'x' * 5_000, 'plan' => 'business' })

    expect(described_class.new(conversation: conversation).attributes).to eq(contact: { 'Plan' => 'business' }, conversation: {})
  end
end
