# frozen_string_literal: true

require 'rails_helper'

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

  it 'does not store attribution outside Chatwoot Cloud' do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
    cookies[described_class::LAST_TOUCH_COOKIE] = encoded_cookie('source' => 'reddit')

    described_class.new(account: account, cookies: cookies).perform

    expect(account.reload.internal_attributes).not_to include('marketing_attribution')
  end

  it 'preserves plus signs from Rails-decoded cookie values' do
    cookies[described_class::LAST_TOUCH_COOKIE] = {
      'source' => 'google',
      'utm_campaign' => 'C++ launch'
    }.to_json

    described_class.new(account: account, cookies: cookies).perform

    attribution = account.reload.internal_attributes['marketing_attribution']
    expect(attribution['last_touch']['utm_campaign']).to eq('C++ launch')
  end

  it 'falls back to percent-decoding raw cookie values' do
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

  def encoded_cookie(payload)
    payload.to_json.bytes.map do |byte|
      character = byte.chr
      character.match?(/[A-Za-z0-9_.~-]/) ? character : "%#{byte.to_s(16).upcase.rjust(2, '0')}"
    end.join
  end
end
