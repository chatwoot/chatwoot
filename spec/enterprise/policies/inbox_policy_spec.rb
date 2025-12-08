require 'rails_helper'

RSpec.describe InboxPolicy do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:inbox) do
    channel = build(:channel_voice, account: account)
    allow(Twilio::VoiceWebhookSetupService).to receive(:new).and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: true))
    channel.save!
    channel.inbox
  end
  let(:policy) { described_class.new(user, inbox) }

  it 'allows conference actions when user can show inbox' do
    allow(policy).to receive(:show?).and_return(true)

    expect(policy.token?).to be true
    expect(policy.create?).to be true
    expect(policy.destroy?).to be true
  end
end
