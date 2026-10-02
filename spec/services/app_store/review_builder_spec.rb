# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppStore::ReviewBuilder do
  let(:channel) { create(:channel_app_store) }
  let(:inbox) { channel.inbox }
  let(:review_payload) do
    {
      'review' => {
        'id' => 'review-1',
        'attributes' => {
          'rating' => 4,
          'title' => 'Helpful app',
          'body' => 'Works well for support.',
          'territory' => 'US',
          'reviewerNickname' => 'Reviewer',
          'createdDate' => '2026-05-20T10:00:00-00:00'
        },
        'relationships' => {
          'response' => {
            'data' => {
              'id' => 'response-1',
              'type' => 'customerReviewResponses'
            }
          }
        }
      },
      'response' => {
        'id' => 'response-1',
        'attributes' => {
          'responseBody' => 'Thanks for the feedback.',
          'state' => 'PUBLISHED',
          'lastModifiedDate' => '2026-05-20T11:00:00-00:00'
        }
      }
    }
  end

  describe '#perform' do
    it 'creates a conversation with an incoming review and outgoing developer response' do
      expect { described_class.new(review_payload: review_payload, channel: channel).perform }
        .to change(inbox.conversations, :count).by(1)
        .and change(Message.where(inbox_id: inbox.id), :count).by(2)

      conversation = inbox.conversations.last
      review_message = conversation.messages.incoming.find_by(source_id: 'review-1')
      response_message = conversation.messages.outgoing.find_by(source_id: 'response-1')

      expect(conversation.contact_inbox.source_id).to eq('review-1')
      expect(review_message.content).to include('★★★★☆ (4/5)', 'Helpful app', 'Works well for support.', 'US • Reviewer')
      expect(review_message.content_attributes['app_store']).to include(
        'rating' => 4,
        'title' => 'Helpful app',
        'territory' => 'US',
        'reviewer_nickname' => 'Reviewer'
      )
      expect(response_message.content).to eq('Thanks for the feedback.')
      expect(response_message.status).to eq('delivered')
      expect(response_message.content_attributes['external_echo']).to be true
    end

    it 'creates a conversation for a rating-only review' do
      rating_only_payload = review_payload.deep_dup
      rating_only_payload['review']['attributes']['title'] = ''
      rating_only_payload['review']['attributes']['body'] = ''
      rating_only_payload['response'] = nil

      expect { described_class.new(review_payload: rating_only_payload, channel: channel).perform }
        .to change(inbox.conversations, :count).by(1)
        .and change(Message.where(inbox_id: inbox.id), :count).by(1)

      review_message = inbox.conversations.last.messages.incoming.find_by(source_id: 'review-1')
      expect(review_message.content).to include('★★★★☆ (4/5)')
    end

    it 'clamps the review rating before building the message content' do
      invalid_rating_payload = review_payload.deep_dup
      invalid_rating_payload['review']['attributes']['rating'] = 7
      invalid_rating_payload['response'] = nil

      described_class.new(review_payload: invalid_rating_payload, channel: channel).perform

      review_message = inbox.conversations.last.messages.incoming.find_by(source_id: 'review-1')
      expect(review_message.content).to include('★★★★★ (5/5)')
      expect(review_message.content_attributes['app_store']).to include('rating' => 5)
    end

    it 'falls back to current time when Apple timestamps are blank' do
      blank_timestamp_payload = review_payload.deep_dup
      blank_timestamp_payload['review']['attributes']['createdDate'] = ''
      blank_timestamp_payload['response']['attributes']['lastModifiedDate'] = ''

      travel_to Time.zone.local(2026, 5, 22, 9, 0, 0) do
        described_class.new(review_payload: blank_timestamp_payload, channel: channel).perform

        conversation = inbox.conversations.last
        expect(conversation.messages.incoming.find_by(source_id: 'review-1').created_at.to_i).to eq(Time.current.to_i)
        expect(conversation.messages.outgoing.find_by(source_id: 'response-1').created_at.to_i).to eq(Time.current.to_i)
      end
    end

    it 'updates an existing review message when Apple returns the same review again' do
      described_class.new(review_payload: review_payload, channel: channel).perform
      updated_payload = review_payload.deep_dup
      updated_payload['review']['attributes']['body'] = 'Updated review body.'

      expect { described_class.new(review_payload: updated_payload, channel: channel).perform }
        .not_to change(Message.where(inbox_id: inbox.id), :count)

      expect(inbox.conversations.last.messages.incoming.find_by(source_id: 'review-1').content).to include('Updated review body.')
    end

    it 'updates an existing developer response message when Apple returns an edited response' do
      described_class.new(review_payload: review_payload, channel: channel).perform
      updated_payload = review_payload.deep_dup
      updated_payload['response']['attributes']['responseBody'] = 'Updated response.'
      updated_payload['response']['attributes']['state'] = 'PENDING_PUBLISH'
      updated_payload['response']['attributes']['lastModifiedDate'] = '2026-05-20T12:00:00-00:00'

      expect { described_class.new(review_payload: updated_payload, channel: channel).perform }
        .not_to change(Message.where(inbox_id: inbox.id), :count)

      response_message = inbox.conversations.last.messages.outgoing.find_by(source_id: 'response-1')
      expect(response_message.content).to eq('Updated response.')
      expect(response_message.content_attributes['app_store']).to include(
        'response_state' => 'PENDING_PUBLISH',
        'response_last_modified_date' => '2026-05-20T12:00:00-00:00'
      )
    end
  end
end
