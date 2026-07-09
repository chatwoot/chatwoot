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

  # Reason (CHANGED from raising ArgumentError): with no account reporting_timezone
  # the campaign schedule must anchor to the São Paulo default (08:00 local =>
  # 11:00 UTC) instead of failing closed — a missing tz can no longer block
  # creating a scheduled campaign, and it never silently means UTC (which would be
  # 08:00 UTC).
  it 'defaults to America/Sao_Paulo when the account timezone is blank: 08:00 local => 11:00 UTC' do
    account, = create_account_and_user
    account.update!(reporting_timezone: nil)

    creator = build(account: account, scheduled_at: '2026-07-08 08:00:00')

    expect(creator.send(:scheduled_at).utc.hour).to eq(11)
  end

  # Reason: the last-resort default is configurable; 08:00 Lisbon in July (WEST,
  # UTC+1) is 07:00 UTC, distinct from both São Paulo and UTC.
  it 'honors CRM_DEFAULT_TIMEZONE for the fallback: 08:00 Europe/Lisbon => 07:00 UTC' do
    account, = create_account_and_user
    account.update!(reporting_timezone: nil)

    creator = build(account: account, scheduled_at: '2026-07-08 08:00:00')

    with_modified_env(CRM_DEFAULT_TIMEZONE: 'Europe/Lisbon') do
      expect(creator.send(:scheduled_at).utc.hour).to eq(7)
    end
  end
end
