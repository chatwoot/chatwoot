require 'rails_helper'

RSpec.describe WhatsappApiCampaigns::Creator do
  def build(account:, scheduled_at:)
    params = ActionController::Parameters.new(scheduled_at: scheduled_at)
    described_class.new(account: account, user: nil, params: params)
  end

  it 'parses scheduled_at in the account timezone: 08:00 local (America/Sao_Paulo) => 11:00 UTC' do
    account, = create_account_and_user
    account.update!(reporting_timezone: 'America/Sao_Paulo')

    creator = build(account: account, scheduled_at: '2026-07-08 08:00:00')

    expect(creator.send(:scheduled_at).utc.hour).to eq(11)
  end

  it 'raises ArgumentError when the account timezone is unresolvable' do
    account, = create_account_and_user
    account.update!(reporting_timezone: nil)

    creator = build(account: account, scheduled_at: '2026-07-08 08:00:00')

    expect { creator.send(:scheduled_at) }.to raise_error(ArgumentError, 'unresolvable_timezone_for_schedule')
  end
end
