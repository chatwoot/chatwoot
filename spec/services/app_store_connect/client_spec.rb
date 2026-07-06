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
                attributes: {
                  createdDate: '2026-05-20T10:00:00-00:00'
                },
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

    it 'keeps fetching older pages so updated developer responses are not skipped' do
      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews')
        .with(query: { include: 'response', limit: '200', sort: '-createdDate' })
        .to_return(app_store_response(mixed_freshness_reviews_page))
      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews?page=2')
        .to_return(app_store_response(older_reviews_page_with_updated_response))

      review_payloads = described_class.new(channel: channel).fetch_reviews(since: Time.zone.parse('2026-05-20T00:00:00-00:00'))

      expect(review_payloads.pluck('review').pluck('id')).to eq(%w[review-1 review-3])
      expect(WebMock).to have_requested(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews?page=2')
    end

    it 'includes older reviews when the developer response was updated after the sync cursor' do
      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews')
        .with(query: { include: 'response', limit: '200', sort: '-createdDate' })
        .to_return(
          status: 200,
          body: {
            data: [
              {
                id: 'review-1',
                type: 'customerReviews',
                attributes: {
                  createdDate: '2026-05-19T10:00:00-00:00'
                },
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
                  responseBody: 'Updated response',
                  lastModifiedDate: '2026-05-20T11:00:00-00:00'
                }
              }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      review_payloads = described_class.new(channel: channel).fetch_reviews(since: Time.zone.parse('2026-05-20T10:00:00-00:00'))

      expect(review_payloads.pluck('review').pluck('id')).to eq(['review-1'])
      expect(review_payloads.first['response']['attributes']['responseBody']).to eq('Updated response')
    end

    it 'fetches a fresh cached token for each request' do
      first_token_service = instance_double(AppStoreConnect::TokenService, token: 'first-token')
      second_token_service = instance_double(AppStoreConnect::TokenService, token: 'second-token')

      allow(AppStoreConnect::TokenService).to receive(:new).with(channel: channel).and_return(first_token_service, second_token_service)

      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews')
        .with(
          headers: { 'Authorization' => 'Bearer first-token' },
          query: { include: 'response', limit: '200', sort: '-createdDate' }
        )
        .to_return(
          status: 200,
          body: {
            data: [],
            links: {
              next: 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews?page=2'
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews?page=2')
        .with(headers: { 'Authorization' => 'Bearer second-token' })
        .to_return(
          status: 200,
          body: { data: [] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      described_class.new(channel: channel).fetch_reviews

      expect(AppStoreConnect::TokenService).to have_received(:new).twice
    end

    def app_store_response(body)
      {
        status: 200,
        body: body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      }
    end

    def mixed_freshness_reviews_page
      {
        data: [
          {
            id: 'review-1',
            type: 'customerReviews',
            attributes: { createdDate: '2026-05-20T10:00:00-00:00' }
          },
          {
            id: 'review-2',
            type: 'customerReviews',
            attributes: { createdDate: '2026-05-19T10:00:00-00:00' }
          }
        ],
        links: {
          next: 'https://api.appstoreconnect.apple.com/v1/apps/123456789/customerReviews?page=2'
        }
      }
    end

    def older_reviews_page_with_updated_response
      {
        data: [
          {
            id: 'review-3',
            type: 'customerReviews',
            attributes: { createdDate: '2026-05-18T10:00:00-00:00' },
            relationships: response_relationship('response-3')
          }
        ],
        included: [updated_response_payload]
      }
    end

    def response_relationship(response_id)
      {
        response: {
          data: { id: response_id, type: 'customerReviewResponses' }
        }
      }
    end

    def updated_response_payload
      {
        id: 'response-3',
        type: 'customerReviewResponses',
        attributes: {
          responseBody: 'Updated response',
          lastModifiedDate: '2026-05-20T11:00:00-00:00'
        }
      }
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

  describe '#create_or_update_review_response' do
    it 'creates or updates a response for a review' do
      stub_request(:post, 'https://api.appstoreconnect.apple.com/v1/customerReviewResponses')
        .with(
          body: {
            data: {
              type: 'customerReviewResponses',
              attributes: {
                responseBody: 'Updated response'
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
          status: 200,
          body: { data: { id: 'response-1' } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = described_class.new(channel: channel).create_or_update_review_response('review-1', 'Updated response')

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
