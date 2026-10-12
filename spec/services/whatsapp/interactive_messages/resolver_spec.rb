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

  it 'persists a resolved native list snapshot before dispatch without attachments' do
    list = {
      schema_version: 1,
      type: 'list',
      body: { text: 'Choose a meal.' },
      action: { button: 'View meals', sections: [{ rows: [{ title: 'Pasta' }, { title: 'Salad', description: 'Fresh' }] }] }
    }
    params = ActionController::Parameters.new(content: 'untrusted', content_attributes: { whatsapp_interactive: list })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      snapshot = message.reload.content_attributes['whatsapp_interactive']
      rows = snapshot.dig('action', 'sections', 0, 'rows')

      expect(message.content).to eq('Choose a meal.')
      expect(rows.pluck('title')).to eq(%w[Pasta Salad])
      expect(rows.pluck('delivery_id').uniq.length).to eq(2)
      expect(rows.last['description']).to eq('Fresh')
      expect(message.attachments).to be_empty
    end
  end

  it 'persists a resolved CTA URL snapshot without generating click identity' do
    cta_url = {
      schema_version: 1,
      type: 'cta_url',
      body: { text: 'Your order is ready.' },
      action: { button: 'View details', url: 'https://example.test/details' }
    }
    params = ActionController::Parameters.new(content: 'untrusted', content_attributes: { whatsapp_interactive: cta_url })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      snapshot = message.reload.content_attributes['whatsapp_interactive']

      expect(message.content).to eq('Your order is ready.')
      expect(snapshot['action']).to eq('button' => 'View details', 'url' => 'https://example.test/details')
      expect(snapshot.to_json).not_to include('delivery_id', 'preset_option_id', 'uuid')
    end
  end

  it 'persists ordered carousel image IDs and every URL card field before dispatch' do
    carousel = {
      schema_version: 1,
      type: 'carousel',
      body: { text: 'Choose a destination.' },
      action: {
        cards: [
          {
            card_index: 0, type: 'cta_url', header: { type: 'image' }, body: { text: 'Mountain escape' },
            action: { button: 'View mountain', url: 'https://example.test/mountain' }
          },
          {
            card_index: 1, type: 'cta_url', header: { type: 'image' },
            action: { button: 'View beach', url: 'https://example.test/beach' }
          }
        ]
      }
    }
    uploads = [
      Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png'),
      Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    ]
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: carousel }, attachments: uploads)

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      cards = message.reload.content_attributes.dig('whatsapp_interactive', 'action', 'cards')

      expect(message.content).to eq('Choose a destination.')
      expect(cards.pluck('card_index')).to eq([0, 1])
      expect(cards.pluck('header').pluck('attachment_id')).to eq(message.attachments.order(:id).pluck(:id))
      expect(cards.first['body']).to eq('text' => 'Mountain escape')
      expect(cards.pluck('action')).to eq(
        [
          { 'button' => 'View mountain', 'url' => 'https://example.test/mountain' },
          { 'button' => 'View beach', 'url' => 'https://example.test/beach' }
        ]
      )
      expect(message.attachments).to all(have_attributes(account_id: account.id, file_type: 'image'))
    end
  end

  it 'persists globally unique carousel reply IDs mapped to their card and option' do
    carousel = {
      schema_version: 1,
      type: 'carousel',
      body: { text: 'Choose a destination.' },
      action: {
        cards: Array.new(2) do |index|
          {
            card_index: index, type: 'button', header: { type: 'image' },
            action: { buttons: [{ title: 'Choose' }, { title: 'Details' }] }
          }
        end
      }
    }
    uploads = Array.new(2) { Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png') }
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: carousel }, attachments: uploads)

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      cards = message.reload.content_attributes.dig('whatsapp_interactive', 'action', 'cards')
      replies = cards.flat_map { |card| card.dig('action', 'buttons') }

      expect(replies.pluck('delivery_id')).to all(start_with('reply_'))
      expect(replies.pluck('delivery_id').uniq.length).to eq(4)
      expect(cards.map { |card| card.dig('action', 'buttons').pluck('title') }).to eq([%w[Choose Details], %w[Choose Details]])
    end
  end

  it 'rejects invalid carousel structure or media before persistence and provider contact' do
    carousel = {
      schema_version: 1,
      type: 'carousel',
      body: { text: 'Choose a destination.' },
      action: {
        cards: Array.new(2) do |index|
          {
            card_index: index, type: 'cta_url', header: { type: 'image' },
            action: { button: 'View', url: "https://example.test/#{index}" }
          }
        end
      }
    }
    image = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    video = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.mp4'), 'video/mp4')
    invalid_inputs = [
      [carousel.deep_dup.tap { |value| value[:action][:cards][1][:type] = 'button' }, [image, image]],
      [carousel, []],
      [carousel, [image]],
      [carousel, [image, image, image]],
      [carousel, [image, video]]
    ]

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_inputs.each do |interactive_payload, uploads|
        params = ActionController::Parameters.new(
          content_attributes: { whatsapp_interactive: interactive_payload }, attachments: uploads
        )
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'persists a CTA URL message-owned media header transactionally' do
    cta_url = {
      schema_version: 1,
      type: 'cta_url',
      header: { type: 'image' },
      body: { text: 'Your order is ready.' },
      action: { button: 'View details', url: 'https://example.test/details' }
    }
    upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: cta_url }, attachments: [upload])

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      attachment = message.attachments.sole

      expect(message.reload.content_attributes.dig('whatsapp_interactive', 'header')).to eq(
        'type' => 'image', 'attachment_id' => attachment.id
      )
      expect(attachment.file_type).to eq('image')
    end
  end

  it 'rejects invalid CTA structure and missing or multiple media uploads before persistence or provider contact' do
    cta_url = {
      schema_version: 1,
      type: 'cta_url',
      header: { type: 'image' },
      body: { text: 'Your order is ready.' },
      action: { button: 'View details', url: 'https://example.test/details' }
    }
    upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    invalid_inputs = [
      [cta_url.deep_dup.tap { |value| value[:action][:url] = 'javascript:alert(1)' }, [upload]],
      [cta_url, []],
      [cta_url, [upload, upload]]
    ]

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_inputs.each do |interactive_payload, uploads|
        params = ActionController::Parameters.new(
          content_attributes: { whatsapp_interactive: interactive_payload }, attachments: uploads
        )
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  it 'rejects an invalid list before persistence or provider contact' do
    invalid_list = {
      schema_version: 1, type: 'list', body: { text: 'Choose.' },
      action: { button: 'Open', sections: [{ rows: [] }] }
    }
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: invalid_list })

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect { Messages::MessageBuilder.new(user, conversation, params).perform }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError)
    end

    expect(conversation.messages.outgoing).to be_empty
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
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
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end

    expect(conversation.messages.outgoing).to be_empty
  end

  { 'image' => ['avatar.png', 'image/png'], 'video' => ['sample.mp4', 'video/mp4'],
    'document' => ['sample.pdf', 'application/pdf'] }.each do |type, file|
    it "persists the message-owned #{type} attachment ID transactionally" do
      interactive[:header] = { type: type }
      interactive[:footer] = { text: 'Footer' }
      upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets', file.first), file.last)
      params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: [upload])

      with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
        message = Messages::MessageBuilder.new(user, conversation, params).perform
        snapshot = message.reload.content_attributes['whatsapp_interactive']
        attachment = message.attachments.sole
        expect(snapshot['header']).to eq('type' => type, 'attachment_id' => attachment.id)
        expect(snapshot['footer']).to eq('text' => 'Footer')
        expect(attachment.account_id).to eq(account.id)
        expect(attachment.file_type).to eq(type == 'document' ? 'file' : type)
      end
    end
  end

  it 'accepts a valid ordinary direct upload signed blob' do
    blob = ActiveStorage::Blob.create_and_upload!(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                                                  content_type: 'image/png')
    interactive[:header] = { type: 'image' }
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: [blob.signed_id])

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      expect(message.attachments.sole.file.blob).to eq(blob)
      expect(message.reload.content_attributes.dig('whatsapp_interactive', 'header', 'attachment_id')).to eq(message.attachments.sole.id)
    end
  end

  it 'lets another account agent send a preset-owned blob after the source message is removed' do
    source_message = create(:message, account: account)
    source_attachment = source_message.attachments.create!(
      account: account, file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    preset = create(
      :whatsapp_interactive_preset,
      account: account,
      created_by: create(:user, account: account),
      definition: interactive.deep_merge(header: { type: 'image' })
    )
    Whatsapp::InteractiveMessages::PresetMedia.sync!(preset, attachments: [source_attachment.file.blob.signed_id])
    reusable_signed_id = preset.media.sole.file.blob.signed_id
    source_message.destroy!
    params = ActionController::Parameters.new(
      content_attributes: { whatsapp_interactive: interactive.deep_merge(header: { type: 'image' }) },
      attachments: [reusable_signed_id]
    )

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      message = Messages::MessageBuilder.new(user, conversation, params).perform
      expect(message.attachments.sole.file.blob).to eq(preset.media.sole.file.blob)
    end
  end

  it 'rejects missing, multiple, mismatched, and forged media before persistence or dispatch' do
    interactive[:header] = { type: 'image' }
    upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.pdf'), 'application/pdf')
    invalid_uploads = [[], [upload, upload], [upload], ['forged-id'], [{ attachment_id: 123 }]]

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      invalid_uploads.each do |uploads|
        params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: uploads)
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }.to raise_error(Whatsapp::InteractiveMessages::ValidationError)
      end
    end
    expect(conversation.messages.outgoing).to be_empty
    expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
  end

  { 'image' => 'image/png', 'video' => 'video/mp4' }.each do |type, content_type|
    it "rejects PDF bytes declared as #{content_type} in multipart upload metadata" do
      interactive[:header] = { type: type }
      upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/sample.pdf'), content_type)
      params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: [upload])

      with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
        expect { Messages::MessageBuilder.new(user, conversation, params).perform }
          .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /must match the selected media type/)
      end

      expect(conversation.messages.outgoing).to be_empty
      expect(WebMock).not_to have_requested(:post, %r{graph\.facebook\.com/.*/messages})
    end
  end

  it 'rejects a signed blob already owned by another account' do
    foreign_message = create(:message)
    foreign_attachment = foreign_message.attachments.create!(
      account_id: foreign_message.account_id, file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    interactive[:header] = { type: 'image' }
    params = ActionController::Parameters.new(
      content_attributes: { whatsapp_interactive: interactive }, attachments: [foreign_attachment.file.blob.signed_id]
    )

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect { Messages::MessageBuilder.new(user, conversation, params).perform }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /another account/)
    end
    expect(conversation.messages.outgoing).to be_empty
  end

  it 'rejects any upload on a text header' do
    interactive[:header] = { type: 'text', text: 'Header' }
    params = ActionController::Parameters.new(content_attributes: { whatsapp_interactive: interactive }, attachments: ['upload'])

    with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
      expect { Messages::MessageBuilder.new(user, conversation, params).perform }
        .to raise_error(Whatsapp::InteractiveMessages::ValidationError, /none otherwise/)
    end
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
