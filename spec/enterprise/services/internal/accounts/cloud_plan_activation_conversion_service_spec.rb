# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::Accounts::CloudPlanActivationConversionService do
  let(:account) { create(:account) }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    create(:installation_config, name: 'CHATWOOT_CLOUD_PLANS', value: [
             { 'name' => 'Hacker' },
             { 'name' => 'Startups' }
           ])
    account.update!(
      internal_attributes: {
        'marketing_attribution' => { 'last_touch' => { 'gclid' => 'test-click-id' } }
      }
    )
  end

  it 'enqueues conversion tracking and marks the activation as tracked' do
    described_class.new(
      account: account,
      previous_plan_name: 'Hacker',
      current_plan_name: 'Startups',
      activated_at: account.created_at + 1.day,
      conversion_value: 398.0,
      currency_code: 'USD'
    ).perform

    expect(Internal::Accounts::MarketingConversionTrackingJob).to have_been_enqueued.with(
      account.id,
      'cloud_plan_activation',
      account.created_at + 1.day,
      398.0,
      'USD'
    )
    expect(account.reload.internal_attributes.dig('marketing_attribution', described_class::PLAN_ACTIVATION_TRACKED_AT)).to be_present
  end

  it 'does not enqueue conversion tracking when plan activation was already tracked' do
    account.update!(
      internal_attributes: {
        'marketing_attribution' => {
          'last_touch' => { 'gclid' => 'test-click-id' },
          described_class::PLAN_ACTIVATION_TRACKED_AT => 1.day.ago.iso8601
        }
      }
    )

    described_class.new(
      account: account,
      previous_plan_name: 'Hacker',
      current_plan_name: 'Startups',
      activated_at: account.created_at + 1.day,
      conversion_value: 398.0,
      currency_code: 'USD'
    ).perform

    expect(Internal::Accounts::MarketingConversionTrackingJob).not_to have_been_enqueued
  end

  it 'does not enqueue conversion tracking outside the signup attribution window' do
    described_class.new(
      account: account,
      previous_plan_name: 'Hacker',
      current_plan_name: 'Startups',
      activated_at: account.created_at + 31.days,
      conversion_value: 398.0,
      currency_code: 'USD'
    ).perform

    expect(Internal::Accounts::MarketingConversionTrackingJob).not_to have_been_enqueued
  end
end
