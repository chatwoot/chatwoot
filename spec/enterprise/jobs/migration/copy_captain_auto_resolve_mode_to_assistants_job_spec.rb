require 'rails_helper'

RSpec.describe Migration::CopyCaptainAutoResolveModeToAssistantsJob, type: :job do
  it 'copies the account mode to assistants without an assistant setting' do
    account = create(:account, captain_auto_resolve_mode: 'legacy')
    assistant = create(:captain_assistant, account: account)
    assistant.update_columns(config: assistant.config.except('auto_resolve_mode')) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now

    expect(assistant.reload.config['auto_resolve_mode']).to eq('legacy')
  end

  it 'preserves an existing assistant setting' do
    account = create(:account, captain_auto_resolve_mode: 'legacy')
    assistant = create(:captain_assistant, account: account, config: { 'auto_resolve_mode' => 'disabled' })

    described_class.perform_now

    expect(assistant.reload.config['auto_resolve_mode']).to eq('disabled')
  end
end
