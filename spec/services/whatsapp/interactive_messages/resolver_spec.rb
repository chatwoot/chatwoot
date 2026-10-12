require 'rails_helper'

RSpec.describe Whatsapp::InteractiveMessages::Resolver do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:contact) { create(:contact, account: account, phone_number: '+15550000001') }
  let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '15550000001') }
  let(:conversation) { create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact_inbox: contact_inbox) }
  let(:interactive) do
    {
      schema_version: 1,
      type: 'button',
      body: { text: 'Please choose one option.' },
      action: { buttons: [{ title: 'Confirm' }, { title: 'Change' }] }
    }
  end

  before do
    account.enable_features!(*Whatsapp::InteractiveMessages::Eligibility::TYPE_FEATURES.values)
    create(:message, :incoming, conversation: conversation, account: account, inbox: conversation.inbox)
  end

  it 'makes MessageBuilder persist the resolved snapshot and body before dispatch' do
    params = ActionController::Parameters.new(
      content: 'untrusted client content',
      content_attributes: { whatsapp_interactive: interactive }
    )

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      expect(message.content).to eq('Please choose one option.')
      snapshot = message.content_attributes['whatsapp_interactive']
      expect(snapshot.except('action')).to eq(
        'schema_version' => 1,
        'type' => 'button',
        'body' => { 'text' => 'Please choose one option.' }
      )
      expect(snapshot.dig('action', 'buttons').pluck('title')).to eq(%w[Confirm Change])
      expect(snapshot.dig('action', 'buttons').pluck('delivery_id')).to all(start_with('reply_'))
      expect(snapshot.dig('action', 'buttons').pluck('delivery_id').uniq.length).to eq(2)
    end
  end

  it 'rejects an ineligible direct create before persistence' do
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000002,+15550000003' do
      expect { Messages::MessageBuilder.new(user, conversation, params).perform }
        .to raise_error(Whatsapp::InteractiveMessages::EligibilityError, 'test_recipient_not_allowlisted')
      expect(conversation.messages.outgoing).to be_empty
    end
  end

  it 'rejects client-owned delivery IDs before persistence' do
    interactive[:action][:buttons].first[:delivery_id] = 'client-id'
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect { Messages::MessageBuilder.new(user, conversation, params).perform }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /unsupported fields: delivery_id/)
      expect(conversation.messages.outgoing).to be_empty
      expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
    end
  end

  it 'rejects attachments and non-text content types before persistence' do
    invalid_params = [
      ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: ['upload']),
      ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, content_type: 'input_select')
    ]

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_params.each do |params|
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /public outgoing text messages without attachments/)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
  end

  it 'rejects template and automation provenance before persistence' do
    invalid_params = [
      ActionController::Parameters.new(
        content_attributes: { whatsapp_interactive: interactive },
        template_params: { name: 'shipping_update' }
      ),
      ActionController::Parameters.new(
        content_attributes: { whatsapp_interactive: interactive, automation_rule_id: 42 }
      )
    ]

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_params.each do |params|
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /template or automation provenance/)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
  end

  it 'leaves an ordinary template request on the existing template lane' do
    params = ActionController::Parameters.new(template_params: { name: 'shipping_update' })

    expect(described_class.message_params(conversation, params, {})).to eq({})
  end

  it 'validates every explicitly supplied whatsapp_interactive value' do
    invalid_values = [{}, [], false, '']

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_values.each do |invalid_value|
        params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: invalid_value })

        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
  end
end
