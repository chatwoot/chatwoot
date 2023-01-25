# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::FacebookPage do
  before do
    stub_request(:post, /graph.facebook.com/)
  end

  let(:channel) { create(:channel_facebook_page) }

  it { is_expected.to validate_presence_of(:account_id) }
  # it { is_expected.to validate_uniqueness_of(:page_id).scoped_to(:account_id) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_one(:inbox).dependent(:destroy_async) }

  describe 'concerns' do
    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for facebook' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:facebook_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end

    context 'when fetch instagram story' do
      let!(:account) { create(:account) }
      let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
      let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
      let(:fb_object) { double }
      let(:message) { create(:message, inbox_id: instagram_inbox.id) }
      let(:instagram_message) { create(:message, :instagram_story_mention, inbox_id: instagram_inbox.id) }

      it '#fetch_instagram_story_link' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          { story:
            {
              mention: {
                link: 'https://www.example.com/test.jpeg',
                id: '17920786367196703'
              }
            },
            from: {
              username: 'Sender-id-1', id: 'Sender-id-1'
            },
            id: 'instagram-message-id-1234' }.with_indifferent_access
        )
        story_link = instagram_channel.fetch_instagram_story_link(message)
        expect(story_link).to eq('https://www.example.com/test.jpeg')
      end

      it '#delete_instagram_story' do
        expect(instagram_message.attachments.count).to eq(1)

        instagram_channel.delete_instagram_story(instagram_message)

        expect(instagram_message.attachments.count).to eq(0)
      end
    end
  end

  it 'has a valid name' do
    expect(channel.name).to eq('Facebook')
  end
end
