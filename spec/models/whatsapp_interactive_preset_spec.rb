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
end
