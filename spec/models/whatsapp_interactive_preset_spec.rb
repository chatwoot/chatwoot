require 'rails_helper'

RSpec.describe WhatsappInteractivePreset do
  let(:account) { create(:account) }
  let(:creator) { create(:user, account: account) }
  let(:definition) do
    {
      schema_version: 1,
      type: 'button',
      body: { text: 'Choose an option' },
      action: { buttons: [{ title: 'Continue' }] }
    }
  end

  it 'normalizes definitions and derives immutable presentation metadata without delivery IDs' do
    preset = described_class.create!(account: account, created_by: creator, name: 'Greeting', definition: definition)

    expect(preset).to have_attributes(interactive_type: 'button', schema_version: 1)
    expect(preset.definition.dig('action', 'buttons', 0)).to eq('title' => 'Continue')
  end

  it 'rejects invalid structures and client-owned technical IDs' do
    definition[:action][:buttons][0][:delivery_id] = 'forged'
    preset = described_class.new(account: account, created_by: creator, name: 'Greeting', definition: definition)

    expect(preset).not_to be_valid
    expect(preset.errors[:definition].join).to include('unsupported fields: delivery_id')
  end

  it 'keeps presets after their creator user is deleted' do
    preset = described_class.create!(account: account, created_by: creator, name: 'Greeting', definition: definition)

    creator.destroy!

    expect(preset.reload.created_by).to be_nil
    expect(preset).not_to be_creator_active
  end

  it 'does not allow ownership to be reassigned' do
    preset = described_class.create!(account: account, created_by: creator, name: 'Greeting', definition: definition)
    replacement = create(:user, account: account)

    expect(preset.update(created_by: replacement)).to be(false)
    expect(preset.errors[:created_by]).to include('cannot be changed')
    expect(preset.reload.created_by).to eq(creator)
  end

  it 'searches names literally without treating wildcard characters as patterns' do
    matching = create(:whatsapp_interactive_preset, account: account, created_by: creator, name: 'Save 100% now')
    create(:whatsapp_interactive_preset, account: account, created_by: creator, name: 'Save 1000 now')

    expect(described_class.search_by_name('100%')).to contain_exactly(matching)
  end

  it 'keeps ordered duplicate carousel blob references through archive and source deletion' do
    source_message = create(:message, account: account)
    source_attachment = source_message.attachments.create!(
      account: account, file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    carousel_definition = {
      schema_version: 1,
      type: 'carousel',
      body: { text: 'Choose a destination' },
      action: {
        cards: Array.new(2) do |index|
          {
            card_index: index, type: 'cta_url', header: { type: 'image' },
            action: { button: 'View', url: "https://example.test/#{index}" }
          }
        end
      }
    }
    preset = described_class.create!(account: account, created_by: creator, name: 'Carousel', definition: carousel_definition)

    Whatsapp::InteractiveMessages::PresetMedia.sync!(
      preset, attachments: [source_attachment.file.blob.signed_id, source_attachment.file.blob.signed_id]
    )
    blob = source_attachment.file.blob

    expect(preset.media.pluck(:position)).to eq([0, 1])
    expect(preset.media.map { |medium| medium.file.blob_id }).to eq([blob.id, blob.id])

    preset.update!(archived_at: Time.current)
    source_message.destroy!

    expect(preset.reload.media.map { |medium| medium.file.blob_id }).to eq([blob.id, blob.id])
    preset.update!(archived_at: nil)
    expect(preset.reload.media.map { |medium| medium.file.blob.signed_id }).to eq([blob.signed_id, blob.signed_id])
    expect(ActiveStorage::Blob.exists?(blob.id)).to be(true)
  end

  it 'retains media after its source conversation and messages are removed' do
    source_message = create(:message, account: account)
    source_attachment = source_message.attachments.create!(
      account: account, file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    blob = source_attachment.file.blob
    media_definition = definition.merge(header: { type: 'image' })
    preset = described_class.create!(account: account, created_by: creator, name: 'Reusable', definition: media_definition)
    Whatsapp::InteractiveMessages::PresetMedia.sync!(preset, attachments: [blob.signed_id])

    source_message.conversation.destroy!
    perform_enqueued_jobs(only: [ActiveRecord::DestroyAssociationAsyncJob, ActiveStorage::PurgeJob])

    expect(preset.reload.media.sole.file.blob).to eq(blob)
    expect(ActiveStorage::Blob.exists?(blob.id)).to be(true)
  end

  it 'allows blob cleanup only after the final message or preset reference is removed' do
    source_message = create(:message, account: account)
    source_attachment = source_message.attachments.create!(
      account: account, file_type: :image,
      file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
    )
    media_definition = definition.merge(header: { type: 'image' })
    first_preset = described_class.create!(account: account, created_by: creator, name: 'First', definition: media_definition)
    second_preset = described_class.create!(account: account, created_by: creator, name: 'Second', definition: media_definition)
    signed_id = source_attachment.file.blob.signed_id
    Whatsapp::InteractiveMessages::PresetMedia.sync!(first_preset, attachments: [signed_id])
    Whatsapp::InteractiveMessages::PresetMedia.sync!(second_preset, attachments: [signed_id])
    blob_id = source_attachment.file.blob_id

    perform_enqueued_jobs do
      source_message.destroy!
      first_preset.destroy!
    end
    expect(ActiveStorage::Blob.exists?(blob_id)).to be(true)

    perform_enqueued_jobs { second_preset.destroy! }
    expect(ActiveStorage::Blob.exists?(blob_id)).to be(false)
  end
end
