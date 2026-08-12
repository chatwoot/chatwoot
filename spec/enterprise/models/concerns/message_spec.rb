# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message do
  let(:account) { create(:account, :without_package) }
  let(:package) { create(:package, campaign_messages_limit: 1) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before { create(:account_package, account: account, package: package) }

  it 'allows campaign messages within the limit' do
    expect { create(:message, account: account, conversation: conversation, additional_attributes: { campaign_id: 1 }) }
      .not_to raise_error
  end

  it 'raises when the account has reached its monthly campaign message limit' do
    create(:message, account: account, conversation: conversation, additional_attributes: { campaign_id: 1 })

    expect do
      create(:message, account: account, conversation: conversation, additional_attributes: { campaign_id: 1 })
    end.to raise_error(CustomExceptions::Message::CampaignLimitExceeded, 'Account limit exceeded. Upgrade to a higher plan')
  end

  it 'does not meter non-campaign messages' do
    create(:message, account: account, conversation: conversation, additional_attributes: { campaign_id: 1 })

    expect do
      create(:message, account: account, conversation: conversation, additional_attributes: {})
    end.not_to raise_error
  end
end
