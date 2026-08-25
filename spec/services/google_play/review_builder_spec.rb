require 'rails_helper'

RSpec.describe GooglePlay::ReviewBuilder do
  let(:channel) { create(:channel_google_play) }
  let(:inbox) { channel.inbox }

  def base_review(overrides = {})
    {
      'reviewId' => 'rev-abc',
      'authorName' => 'Jane Reviewer',
      'comments' => [
        { 'userComment' => {
          'text' => 'Great app, but crashes sometimes.',
          'starRating' => 4,
          'reviewerLanguage' => 'en',
          'appVersionName' => '4.5.0',
          'androidOsVersion' => 33,
          'device' => 'a15',
          'deviceMetadata' => { 'productName' => 'Galaxy A15', 'manufacturer' => 'Samsung' },
          'lastModified' => { 'seconds' => '1779000000', 'nanos' => 0 }
        } }
      ]
    }.deep_merge(overrides)
  end

  it 'creates a contact, conversation, and incoming message from userComment' do
    expect do
      described_class.new(review: base_review, channel: channel).perform
    end.to change(Contact, :count).by(1)
                                  .and change(Conversation, :count).by(1)
                                                                   .and change(Message, :count).by(1)

    message = Message.last
    expect(message.message_type).to eq 'incoming'
    expect(message.source_id).to eq 'rev-abc::1779000000'
    expect(message.content).to include('★★★★☆ (4/5)')
    expect(message.content).to include('Great app, but crashes sometimes.')
    expect(message.content).to include('Galaxy A15 • v4.5.0 • Android 33')
    expect(message.content_attributes['google_play']).to include(
      'star_rating' => 4,
      'app_version' => '4.5.0',
      'manufacturer' => 'Samsung',
      'reviewer_language' => 'en'
    )
  end

  it 'is idempotent for the same userComment lastModified seconds' do
    described_class.new(review: base_review, channel: channel).perform

    expect do
      described_class.new(review: base_review, channel: channel).perform
    end.not_to change(Message, :count)
  end

  it 'creates a new incoming message when the reviewer edits (new lastModified)' do
    described_class.new(review: base_review, channel: channel).perform

    edited = base_review.deep_dup
    edited['comments'].first['userComment']['lastModified']['seconds'] = '1779999999'
    edited['comments'].first['userComment']['text'] = 'Edited review'

    expect do
      described_class.new(review: edited, channel: channel).perform
    end.to change(Message, :count).by(1)
                                  .and(not_change(Conversation, :count))
  end

  it 'skips entirely when the user comment text is blank' do
    review = base_review
    review['comments'].first['userComment']['text'] = ''

    expect do
      described_class.new(review: review, channel: channel).perform
    end.to(not_change(Message, :count))
  end

  context 'when the review also has a developerComment' do
    let(:review_with_reply) do
      base_review('comments' => [
                    { 'userComment' => base_review['comments'].first['userComment'] },
                    { 'developerComment' => {
                      'text' => 'Thanks for the feedback!',
                      'lastModified' => { 'seconds' => '1779100000' }
                    } }
                  ])
    end

    it 'mirrors the developer comment as an outgoing message' do
      described_class.new(review: review_with_reply, channel: channel).perform

      outgoing = Message.outgoing.last
      expect(outgoing.content).to eq('Thanks for the feedback!')
      expect(outgoing.source_id).to eq('rev-abc::reply::1779100000')
      expect(outgoing.status).to eq('sent')
    end

    it 'is idempotent and does not duplicate the outgoing reply' do
      described_class.new(review: review_with_reply, channel: channel).perform

      expect do
        described_class.new(review: review_with_reply, channel: channel).perform
      end.not_to change(Message, :count)
    end

    it 'dedupes against a reply already sent through Chatwoot with the same source_id' do
      conversation = create(:conversation, inbox: inbox, account: channel.account,
                                           contact_inbox: create(:contact_inbox, inbox: inbox, source_id: 'rev-abc'))
      create(:message, conversation: conversation, account: channel.account, inbox: inbox,
                       message_type: :outgoing, source_id: 'rev-abc::reply::1779100000', content: 'sent via chatwoot')

      expect do
        described_class.new(review: review_with_reply, channel: channel).perform
      end.to change(Message, :count).by(1) # the incoming user message only
      expect(Message.outgoing.where(source_id: 'rev-abc::reply::1779100000').count).to eq(1)
    end
  end

  # RSpec helper for `not_change` (no built-in opposite of `change`)
  matcher :not_change do |obj, method|
    supports_block_expectations
    match do |block|
      before = obj.send(method)
      block.call
      obj.send(method) == before
    end
  end
end
