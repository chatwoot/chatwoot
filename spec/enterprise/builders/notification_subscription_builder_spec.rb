# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotificationSubscriptionBuilder do
  let(:user) { create(:user) }

  def register(type, attributes)
    described_class.new(
      user: user,
      params: ActionController::Parameters.new(subscription_type: type, subscription_attributes: attributes).permit!
    ).perform
  end

  it 'keys a phone by its device id' do
    subscription = register('fcm', { push_token: 'fcm-token', device_id: 'phone-1', devicePlatform: 'Android' })

    expect(subscription.identifier).to eq('phone-1')
    expect(subscription).to be_fcm
  end

  it 'keeps a VoIP token as a second row for the same phone' do
    fcm = register('fcm', { push_token: 'fcm-token', device_id: 'phone-1', devicePlatform: 'iOS' })
    voip = register('apns_voip', { push_token: 'voip-token', device_id: 'phone-1', devicePlatform: 'iOS' })

    expect(voip.identifier).to eq('voip:phone-1')
    expect(voip).to be_apns_voip
    expect(voip).not_to eq(fcm)
    expect(user.notification_subscriptions.count).to eq(2)
  end

  it 'updates the VoIP row in place when the token rotates' do
    first = register('apns_voip', { push_token: 'voip-1', device_id: 'phone-1' })
    second = register('apns_voip', { push_token: 'voip-2', device_id: 'phone-1' })

    expect(second.id).to eq(first.id)
    expect(second.subscription_attributes['push_token']).to eq('voip-2')
  end
end
