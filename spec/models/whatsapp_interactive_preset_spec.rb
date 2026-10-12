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
    expect(preset.definition.dig('action', 'buttons', 0)).to include('title' => 'Continue')
    expect(preset.definition.dig('action', 'buttons', 0, 'preset_option_id')).to match(
      /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    )
    expect(preset.definition.to_json).not_to include('delivery_id')
  end

  it 'keeps same-parent identities through reorder and surrounding edits but replaces changed or missing identities' do
    preset = described_class.create!(
      account: account, created_by: creator, name: 'Greeting',
      definition: definition.deep_merge(action: { buttons: [{ title: 'Continue' }, { title: 'Stop' }] })
    )
    original_ids = preset.definition.dig('action', 'buttons').index_by { |button| button['title'] }.transform_values do |button|
      button['preset_option_id']
    end
    updated = preset.definition.deep_dup
    updated['body']['text'] = 'Updated surrounding copy'
    updated['action']['buttons'].reverse!
    updated['action']['buttons'].first['title'] = 'Changed'
    updated['action']['buttons'].last.delete('preset_option_id')

    preset.update!(definition: updated)
    changed, missing = preset.definition.dig('action', 'buttons')

    expect(changed['preset_option_id']).not_to eq(original_ids['Stop'])
    expect(missing['preset_option_id']).not_to eq(original_ids['Continue'])
  end

  it 'preserves list rows only inside their authoritative section and includes description in owned fields' do
    list_definition = {
      schema_version: 1, type: 'list', body: { text: 'Choose' }, action: {
        button: 'Open', sections: [
          { title: 'First', rows: [{ title: 'Alpha', description: 'A' }, { title: 'Beta' }] },
          { title: 'Second', rows: [{ title: 'Gamma' }] }
        ]
      }
    }
    preset = described_class.create!(account: account, created_by: creator, name: 'List', definition: list_definition)
    original = preset.definition.deep_dup
    updated = preset.definition.deep_dup
    updated['action']['sections'][0]['rows'].reverse!
    updated['action']['sections'][0]['rows'][1]['description'] = 'Changed'
    moved = updated['action']['sections'][0]['rows'].shift
    updated['action']['sections'][1]['rows'] << moved

    preset.update!(definition: updated)
    rows = preset.definition.dig('action', 'sections').flat_map { |section| section['rows'] }.index_by { |row| row['title'] }

    expect(rows['Alpha']['preset_option_id']).not_to eq(original.dig('action', 'sections', 0, 'rows', 0, 'preset_option_id'))
    expect(rows['Beta']['preset_option_id']).not_to eq(original.dig('action', 'sections', 0, 'rows', 1, 'preset_option_id'))
    expect(rows['Gamma']['preset_option_id']).to eq(original.dig('action', 'sections', 1, 'rows', 0, 'preset_option_id'))
  end

  it 'preserves carousel replies within a card, replaces moved replies, and never identifies URL actions' do
    carousel = {
      schema_version: 1, type: 'carousel', body: { text: 'Choose' }, action: { cards: Array.new(2) do |index|
        {
          card_index: index, type: 'button', header: { type: 'image' }, body: { text: "Card #{index}" },
          action: { buttons: [{ title: "Choose #{index}" }, { title: "Details #{index}" }] }
        }
      end }
    }
    preset = described_class.create!(account: account, created_by: creator, name: 'Carousel', definition: carousel)
    original = preset.definition.deep_dup
    updated = preset.definition.deep_dup
    updated['action']['cards'][0]['body']['text'] = 'Surrounding card copy changed'
    updated['action']['cards'][0]['action']['buttons'].reverse!
    moved = updated['action']['cards'][0]['action']['buttons'].shift
    displaced = updated['action']['cards'][1]['action']['buttons'].shift
    updated['action']['cards'][1]['action']['buttons'] << moved
    updated['action']['cards'][0]['action']['buttons'] << displaced

    preset.update!(definition: updated)
    first_card_reply = preset.definition.dig('action', 'cards', 0, 'action', 'buttons', 0)
    moved_reply = preset.definition.dig('action', 'cards', 1, 'action', 'buttons', 1)

    expect(first_card_reply['preset_option_id']).to eq(original.dig('action', 'cards', 0, 'action', 'buttons', 0, 'preset_option_id'))
    expect(moved_reply['preset_option_id']).not_to eq(original.dig('action', 'cards', 0, 'action', 'buttons', 1, 'preset_option_id'))

    url_carousel = carousel.deep_dup
    url_carousel[:action][:cards].each_with_index do |card, index|
      card[:type] = 'cta_url'
      card[:action] = { button: 'View', url: "https://example.test/#{index}" }
    end
    url_preset = described_class.create!(account: account, created_by: creator, name: 'URLs', definition: url_carousel)
    expect(url_preset.definition.to_json).not_to include('preset_option_id')
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
