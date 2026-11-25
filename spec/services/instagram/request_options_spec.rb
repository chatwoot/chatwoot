require 'rails_helper'

# The ceilings for the Instagram family, and the two places that cannot report their own
# absence.
RSpec.describe Instagram::RequestOptions do
  # Three of this family's call sites sit inside a `rescue StandardError` that answers with
  # something plausible: `subscribe` and `unsubscribe` answer `true`, and a failed token
  # refresh answers the token it already had. A constant that does not resolve raises
  # `NameError`, which is a `StandardError`, so forgetting the `include` in one of those
  # files produces a channel that never subscribed and a token that is never refreshed,
  # with nothing in the logs above debug level. That is not a hypothesis: writing this
  # slice, the two files that needed the `include` were exactly the two that swallow, and
  # only the token-refresh spec noticed.
  describe 'the calls whose failure is swallowed' do
    let(:channel) { create(:channel_instagram, access_token: 'a-token', expires_at: 20.days.from_now) }
    let(:answer) do
      instance_double(HTTParty::Response, success?: true, body: '{"access_token":"x","expires_in":1}',
                                          parsed_response: { 'access_token' => 'x', 'expires_in' => 1 })
    end

    it 'sends the ceiling when telling Instagram what to notify us about' do
      options = nil
      allow(HTTParty).to receive(:post) { |_url, **kwargs| options = kwargs and answer }

      channel.subscribe

      expect(options).to include(timeout: 10, max_retries: 0)
    end

    it 'sends the ceiling when it stops asking to be notified' do
      options = nil
      allow(HTTParty).to receive(:delete) { |_url, **kwargs| options = kwargs and answer }

      channel.unsubscribe

      expect(options).to include(timeout: 10, max_retries: 0)
    end

    # This one answers with the token it already had on any failure, so a ceiling that
    # never applied would show up as a token quietly never refreshed. Answered as a
    # refusal on purpose: what is under test is the options the call went out with, and a
    # refusal keeps the example out of the whole token-rotation chain that follows a
    # successful answer.
    it 'sends the ceiling when refreshing the long-lived token' do
      options = nil
      refused = instance_double(HTTParty::Response, success?: false, body: '{}')
      allow(HTTParty).to receive(:get) { |_url, **kwargs| options = kwargs and refused }
      channel.update!(expires_at: 5.days.from_now)
      allow(channel).to receive(:updated_at).and_return(25.hours.ago)

      expect(Instagram::RefreshOauthTokenService.new(channel: channel).access_token).to eq('a-token')
      expect(options).to include(timeout: 10, max_retries: 0)
    end
  end

  # A fence, not a checklist. Counted per ceiling so that moving a call between them has to
  # be deliberate, and the total counted separately so a new call cannot arrive without one.
  it 'puts every Instagram call under one of the two ceilings' do
    sources = %w[
      app/models/channel/instagram.rb
      app/controllers/concerns/instagram_concern.rb
      app/builders/messages/instagram/message_builder.rb
      app/services/instagram/message_text.rb
      app/services/instagram/refresh_oauth_token_service.rb
      app/services/instagram/send_on_instagram_service.rb
      app/services/instagram/messenger/send_on_instagram_service.rb
    ].map { |path| File.read(Rails.root.join(path)) }.join

    expect(sources.scan(/HTTParty\.\w+/).size).to eq(8)
    expect(sources.scan('INSTAGRAM_SHORT_REQUEST_OPTIONS').size).to eq(6)
    expect(sources.scan('INSTAGRAM_REQUEST_OPTIONS').size).to eq(2)
  end
end
