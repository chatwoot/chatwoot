# frozen_string_literal: true

require 'rails_helper'
require 'base64'

RSpec.describe Internal::Accounts::MarketingAttributionService do
  let(:account) { create(:account) }
  let(:cookies) { {} }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
  end

  it 'stores website attribution cookies on the account' do
    cookies[described_class::FIRST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'reddit',
      'source_type' => 'paid_social',
      'referrer' => 'https://reddit.com',
      'referrer_path' => '/r/selfhosted/comments/123/chatwoot'
    )
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'github',
      'source_type' => 'referral'
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['captured_from']).to eq('cookie')
    expect(attribution['first_touch']['source']).to eq('reddit')
    expect(attribution['first_touch']['referrer_path']).to eq('/r/selfhosted/comments/123/chatwoot')
    expect(attribution['last_touch']['source']).to eq('github')
  end

  it 'enqueues signup conversion tracking after storing attribution' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie('source' => 'github')

    expect do
      described_class.new(account: account, cookies: cookies).perform
    end.to have_enqueued_job(Internal::Accounts::MarketingConversionTrackingJob)
      .with(account.id, 'cloud_signup', account.created_at)
  end

  it 'does not store attribution outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie('source' => 'reddit')

    described_class.new(account: account, cookies: cookies).perform

    expect(account.reload.internal_attributes).not_to include('marketing_attribution')
  end

  it 'decodes base64url cookie values and preserves plus signs' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'google',
      'utm_campaign' => 'C++ launch'
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']['utm_campaign']).to eq('C++ launch')
  end

  it 'preserves an existing touch when the matching cookie is absent' do
    account.update!(
      internal_attributes: {
        'marketing_attribution' => {
          'first_touch' => { 'source' => 'reddit' },
          'last_touch' => { 'source' => 'github' }
        }
      }
    )
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie('source' => 'google')

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['first_touch']['source']).to eq('reddit')
    expect(attribution['last_touch']['source']).to eq('google')
  end

  it 'preserves other internal attributes' do
    account.update!(internal_attributes: { 'manually_managed_features' => ['inbound_emails'] })
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie('source' => 'google')

    described_class.new(account: account, cookies: cookies).perform

    expect(account.reload.internal_attributes['manually_managed_features']).to eq(['inbound_emails'])
  end

  it 'ignores parsed cookies that are not populated attribution objects' do
    account.update!(
      internal_attributes: {
        'marketing_attribution' => {
          'first_touch' => { 'source' => 'reddit' },
          'last_touch' => { 'source' => 'github' }
        }
      }
    )
    cookies[described_class::FIRST_TOUCH_COOKIE] = {}.to_json
    cookies[described_class::LAST_TOUCH_COOKIE] = [].to_json

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['first_touch']['source']).to eq('reddit')
    expect(attribution['last_touch']['source']).to eq('github')
  end

  it 'stores only allowlisted scalar attribution fields' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'google',
      'source_type' => 'paid_search',
      'utm_campaign' => 'spring',
      'unknown_field' => 'ignore me',
      'nested' => { 'value' => 'ignore me' },
      'array' => ['ignore me']
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']).to eq(
      'source' => 'google',
      'source_type' => 'paid_search',
      'utm_campaign' => 'spring'
    )
  end

  it 'truncates oversized attribution values' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'google',
      'utm_campaign' => 'a' * 600
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']['utm_campaign'].length).to eq(described_class::FIELD_MAX_LENGTH)
  end

  it 'stores raw attribution values without escaping them' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => '<script>alert(1)</script>',
      'utm_campaign' => 'launch & learn'
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']['source']).to eq('<script>alert(1)</script>')
    expect(attribution['last_touch']['utm_campaign']).to eq('launch & learn')
  end

  it 'caps raw attribution values' do
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie(
      'source' => 'google',
      'utm_campaign' => '&' * 600
    )

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']['utm_campaign'].length).to eq(described_class::FIELD_MAX_LENGTH)
  end

  def encoded_cookie(payload)
    Base64.urlsafe_encode64(payload.to_json, padding: false)
  end
end
