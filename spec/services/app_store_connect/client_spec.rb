# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppStoreConnect::Client do
  let(:channel) { create(:channel_app_store, app_id: '123456789') }
  let(:token_service) { instance_double(AppStoreConnect::TokenService, token: 'jwt-token') }

  before do
    allow(AppStoreConnect::TokenService).to receive(:new).with(channel: channel).and_return(token_service)
  end

  describe '#fetch_app' do
    it 'fetches the configured app' do
      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789')
        .with(headers: { 'Authorization' => 'Bearer jwt-token' })
        .to_return(
          status: 200,
          body: {
            data: {
              id: '123456789',
              attributes: {
                name: 'Chatwoot',
                bundleId: 'com.chatwoot.app'
              }
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(described_class.new(channel: channel).fetch_app['id']).to eq('123456789')
    end
  end

  describe '#fetch_reviews' do
    it 'fetches reviews and attaches the included developer response' do
      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews')
        .with(query: { include: 'response', limit: '200', sort: '-createdDate' })
        .to_return(
          status: 200,
          body: {
            data: [
              {
                id: 'review-1',
                type: 'customerReviews',
                relationships: {
                  response: {
                    data: {
                      id: 'response-1',
                      type: 'customerReviewResponses'
                    }
                  }
                }
              }
            ],
            included: [
              {
                id: 'response-1',
                type: 'customerReviewResponses',
                attributes: {
                  responseBody: 'Thanks for the review'
                }
              }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      review_payload = described_class.new(channel: channel).fetch_reviews.first

      expect(review_payload['review']['id']).to eq('review-1')
      expect(review_payload['response']['id']).to eq('response-1')
    end
  end

  describe '#create_review_response' do
    it 'creates a response for a review' do
      stub_request(:post, 'https://api.appstoreconnect.apple.com/v1/customerReviewResponses')
        .with(
          body: {
            data: {
              type: 'customerReviewResponses',
              attributes: {
                responseBody: 'Thanks'
              },
              relationships: {
                review: {
                  data: {
                    type: 'customerReviews',
                    id: 'review-1'
                  }
                }
              }
            }
          }.to_json
        )
        .to_return(
          status: 201,
          body: { data: { id: 'response-1' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.new(channel: channel).create_review_response('review-1', 'Thanks')

      expect(response['id']).to eq('response-1')
    end
  end

  describe '#update_review_response' do
    it 'updates an existing response' do
      stub_request(:patch, 'https://api.appstoreconnect.apple.com/v1/customerReviewResponses/response-1')
        .with(
          body: {
            data: {
              type: 'customerReviewResponses',
              id: 'response-1',
              attributes: {
                responseBody: 'Updated response'
              }
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: { data: { id: 'response-1' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.new(channel: channel).update_review_response('response-1', 'Updated response')

      expect(response['id']).to eq('response-1')
    end
  end

  it 'raises a useful error when Apple returns an error response' do
    stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789')
      .to_return(
        status: 401,
        body: {
          errors: [
            {
              detail: 'Provide a properly configured and signed bearer token.'
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect { described_class.new(channel: channel).fetch_app }
      .to raise_error(AppStoreConnect::Client::Error, /properly configured and signed bearer token/)
  end
end
