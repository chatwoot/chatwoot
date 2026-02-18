require 'rails_helper'

RSpec.describe X::Client do
  let(:bearer_token) { 'test-bearer-token' }
  let(:client) { described_class.new(bearer_token: bearer_token) }

  describe '#send_direct_message' do
    it 'sends a DM with text' do
      stub_request(:post, 'https://api.x.com/2/dm_conversations/with/67890/messages')
        .with(
          body: { text: 'Hello!' }.to_json,
          headers: {
            'Authorization' => "Bearer #{bearer_token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 201,
          body: { id: 'dm-123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.send_direct_message(participant_id: '67890', text: 'Hello!')

      expect(result['id']).to eq('dm-123')
    end

    it 'sends a DM with attachments' do
      attachments = [{ media_id: 'media-123' }]

      stub_request(:post, 'https://api.x.com/2/dm_conversations/with/67890/messages')
        .with(
          body: { text: 'Check this', attachments: attachments }.to_json
        )
        .to_return(
          status: 201,
          body: { id: 'dm-124' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.send_direct_message(participant_id: '67890', text: 'Check this', attachments: attachments)

      expect(result['id']).to eq('dm-124')
    end
  end

  describe '#create_tweet' do
    it 'creates a tweet' do
      stub_request(:post, 'https://api.x.com/2/tweets')
        .with(
          body: { text: 'Hello X!' }.to_json,
          headers: {
            'Authorization' => "Bearer #{bearer_token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 201,
          body: { id: 'tweet-456' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.create_tweet(text: 'Hello X!')

      expect(result['id']).to eq('tweet-456')
    end

    it 'creates a tweet reply' do
      stub_request(:post, 'https://api.x.com/2/tweets')
        .with(
          body: {
            text: 'Reply tweet',
            reply: { in_reply_to_tweet_id: 'tweet-123' }
          }.to_json
        )
        .to_return(
          status: 201,
          body: { id: 'tweet-789' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.create_tweet(text: 'Reply tweet', reply_to_tweet_id: 'tweet-123')

      expect(result['id']).to eq('tweet-789')
    end
  end

  describe '#user' do
    it 'fetches user by ID' do
      stub_request(:get, 'https://api.x.com/2/users/12345?user.fields=profile_image_url,name,username')
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(
          status: 200,
          body: {
            data: {
              id: '12345',
              username: 'johndoe',
              name: 'John Doe',
              profile_image_url: 'https://example.com/avatar.jpg'
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.user('12345')

      expect(result['data']['username']).to eq('johndoe')
    end
  end

  describe '#me' do
    it 'fetches authenticated user' do
      stub_request(:get, 'https://api.x.com/2/users/me?user.fields=profile_image_url,name,username')
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(
          status: 200,
          body: {
            data: {
              id: '12345',
              username: 'myaccount',
              name: 'My Account'
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      result = client.me

      expect(result['data']['username']).to eq('myaccount')
    end
  end

  describe 'error handling' do
    it 'raises UnauthorizedError for 401 responses' do
      stub_request(:post, 'https://api.x.com/2/dm_conversations/with/67890/messages')
        .to_return(
          status: 401,
          body: { errors: [{ message: 'Unauthorized' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.send_direct_message(participant_id: '67890', text: 'Hello!')
      end.to raise_error(X::Errors::UnauthorizedError, 'Token expired or invalid')
    end

    it 'raises RateLimitError for 429 responses' do
      reset_time = (15.minutes.from_now).to_i

      stub_request(:post, 'https://api.x.com/2/dm_conversations/with/67890/messages')
        .to_return(
          status: 429,
          headers: {
            'x-rate-limit-reset' => reset_time.to_s,
            'Content-Type' => 'application/json'
          },
          body: { errors: [{ message: 'Rate limit exceeded' }] }.to_json
        )

      expect do
        client.send_direct_message(participant_id: '67890', text: 'Hello!')
      end.to raise_error(X::Errors::RateLimitError, /Rate limit exceeded/)
    end

    it 'raises APIError for other error responses' do
      stub_request(:post, 'https://api.x.com/2/dm_conversations/with/67890/messages')
        .to_return(
          status: 400,
          body: { errors: [{ message: 'Bad request' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.send_direct_message(participant_id: '67890', text: 'Hello!')
      end.to raise_error(X::Errors::ApiError, /Bad request/)
    end
  end
end
