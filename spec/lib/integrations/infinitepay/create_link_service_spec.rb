# frozen_string_literal: true

require 'rails_helper'

describe Integrations::Infinitepay::CreateLinkService do
  describe '#perform' do
    subject(:payment_link) do
      with_modified_env 'FRONTEND_URL' => 'https://chatwit.witdev.com.br' do
        described_class.new(
          account: account,
          conversation: conversation,
          user: user,
          amount_cents: 12_345,
          description: 'Honorarios'
        ).perform
      end
    end

    let(:account) { create(:account, custom_attributes: { 'infinitepay_handle' => 'witdev-test' }) }
    let(:user) { create(:user, account: account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:checkout_url) { 'https://checkout.infinitepay.com.br/witdev-test?lenc=abc123' }
    let(:request_url) { 'https://api.checkout.infinitepay.io/links' }

    it 'creates the payment link through the current InfinitePay checkout API' do
      request = stub_request(:post, request_url)
                .with(
                  headers: { 'Content-Type' => 'application/json' }
                ) do |req|
                  body = JSON.parse(req.body)

                  body['handle'] == 'witdev-test' &&
                    body['redirect_url'].end_with?("/app/accounts/#{account.id}/conversations/#{conversation.display_id}") &&
                    body['webhook_url'] == 'https://chatwit.witdev.com.br/webhooks/infinitepay' &&
                    body['items'].first.slice('quantity', 'price') == { 'quantity' => 1, 'price' => 12_345 } &&
                    body['items'].first['description'].include?('Honorarios')
                end
                .to_return(
                  status: 200,
                  body: { url: checkout_url }.to_json,
                  headers: { 'Content-Type' => 'application/json' }
                )

      expect(payment_link.checkout_url).to eq(checkout_url)
      expect(payment_link.status).to eq('pending')
      expect(request).to have_been_requested.once
    end
  end
end
