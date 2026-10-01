require 'rails_helper'

describe Sms::IncomingMessageService do
  describe '#perform' do
    let!(:sms_channel) { create(:channel_sms) }
    let(:params) do
      {

        'id': '3232420-2323-234324',
        'owner': sms_channel.phone_number,
        'applicationId': '2342349-324234d-32432432',
        'time': '2022-02-02T23:14:05.262Z',
        'segmentCount': 1,
        'direction': 'in',
        'to': [
          sms_channel.phone_number
        ],
        'from': '+14234234234',
        'text': 'test message'

      }.with_indifferent_access
    end

    # Non-provider media is fetched through SafeFetch (SsrfFilter), which resolves the
    # host and rejects private addresses. Stub resolution to public IPs for test hosts.
    before do
      allow(Resolv).to receive(:getaddresses).and_call_original
      allow(Resolv).to receive(:getaddresses).with('test.com').and_return(['93.184.216.34'])
      allow(Resolv).to receive(:getaddresses).with('other.example').and_return(['93.184.216.34'])
      allow(Resolv).to receive(:getaddresses).with('internal.example').and_return(['169.254.169.254'])
    end

    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        expect(sms_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('+1 423-423-4234')
        expect(sms_channel.inbox.messages.first.content).to eq(params[:text])
      end

      it 'appends to last conversation when if conversation already exisits' do
        contact_inbox = create(:contact_inbox, inbox: sms_channel.inbox, source_id: params[:from])
        2.times.each { create(:conversation, inbox: sms_channel.inbox, contact_inbox: contact_inbox) }
        last_conversation = create(:conversation, inbox: sms_channel.inbox, contact_inbox: contact_inbox)
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(sms_channel.inbox.conversations.count).to eq(3)
        # message appended to the last conversation
        expect(last_conversation.messages.last.content).to eq(params[:text])
      end

      it 'reopen last conversation if last conversation is resolved and lock to single conversation is enabled' do
        sms_channel.inbox.update(lock_to_single_conversation: true)
        contact_inbox = create(:contact_inbox, inbox: sms_channel.inbox, source_id: params[:from])
        last_conversation = create(:conversation, inbox: sms_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update(status: 'resolved')
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        # no new conversation should be created
        expect(sms_channel.inbox.conversations.count).to eq(1)
        expect(sms_channel.inbox.conversations.open.last.messages.last.content).to eq(params[:text])
        expect(sms_channel.inbox.conversations.open.last.status).to eq('open')
      end

      it 'creates a new conversation if last conversation is resolved and lock to single conversation is disabled' do
        sms_channel.inbox.update(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: sms_channel.inbox, source_id: params[:from])
        last_conversation = create(:conversation, inbox: sms_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update(status: 'resolved')
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        # new conversation should be created
        expect(sms_channel.inbox.conversations.count).to eq(2)
        # message appended to the last conversation
        expect(contact_inbox.conversations.last.messages.last.content).to eq(params[:text])
      end

      it 'will not create a new conversation if last conversation is not resolved and lock to single conversation is disabled' do
        sms_channel.inbox.update(lock_to_single_conversation: false)
        contact_inbox = create(:contact_inbox, inbox: sms_channel.inbox, source_id: params[:from])
        last_conversation = create(:conversation, inbox: sms_channel.inbox, contact_inbox: contact_inbox)
        last_conversation.update(status: Conversation.statuses.except('resolved').keys.sample)
        described_class.new(inbox: sms_channel.inbox, params: params).perform
        # new conversation should be created
        expect(sms_channel.inbox.conversations.count).to eq(1)
        # message appended to the last conversation
        expect(contact_inbox.conversations.last.messages.last.content).to eq(params[:text])
      end

      it 'creates attachment messages and ignores .smil files' do
        stub_request(:get, 'http://test.com/test.png').to_return(status: 200, body: File.read('spec/assets/sample.png'),
                                                                 headers: { 'Content-Type' => 'image/png' })
        stub_request(:get, 'http://test.com/test2.png').to_return(status: 200, body: File.read('spec/assets/sample.png'),
                                                                  headers: { 'Content-Type' => 'image/png' })

        media_params = { 'media': [
          'http://test.com/test.smil',
          'http://test.com/test.png',
          'http://test.com/test2.png'
        ] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform
        expect(sms_channel.inbox.conversations.count).not_to eq(0)
        expect(Contact.all.first.name).to eq('+1 423-423-4234')
        expect(sms_channel.inbox.messages.first.content).to eq('test message')
        expect(sms_channel.inbox.messages.first.attachments.present?).to be true
      end
    end

    context 'when downloading media attachments' do
      let(:provider_media_url) { 'https://messaging.bandwidth.com/api/v2/users/1/media/real.png' }

      it 'attaches provider credentials only for media on the provider host' do
        stub_request(:get, provider_media_url).to_return(status: 200, body: File.read('spec/assets/sample.png'))
        media_params = { 'media': [provider_media_url] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(a_request(:get, provider_media_url).with(basic_auth: %w[1 1])).to have_been_made
      end

      it 'downloads media from other hosts without provider credentials' do
        stub_request(:get, 'http://other.example/file.png').to_return(status: 200, body: File.read('spec/assets/sample.png'),
                                                                      headers: { 'Content-Type' => 'image/png' })
        media_params = { 'media': ['http://other.example/file.png'] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(a_request(:get, 'http://other.example/file.png').with(basic_auth: %w[1 1])).not_to have_been_made
        expect(sms_channel.inbox.messages.first.attachments.present?).to be true
      end

      it 'does not attach credentials to a plaintext provider url' do
        http_url = 'http://messaging.bandwidth.com/api/v2/users/1/media/real.png'
        stub_request(:get, http_url).to_return(status: 200, body: File.read('spec/assets/sample.png'))
        media_params = { 'media': [http_url] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(a_request(:get, http_url).with(basic_auth: %w[1 1])).not_to have_been_made
      end

      it 'does not attach credentials to a provider url on a non-default port' do
        url = 'https://messaging.bandwidth.com:8443/api/v2/users/1/media/real.png'
        stub_request(:get, url).to_return(status: 200, body: File.read('spec/assets/sample.png'))
        media_params = { 'media': [url] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(a_request(:get, url).with(basic_auth: %w[1 1])).not_to have_been_made
      end

      it 'does not attach credentials to a provider url with embedded userinfo' do
        stub_request(:get, provider_media_url).to_return(status: 200, body: File.read('spec/assets/sample.png'))
        media_params = { 'media': ['https://user@messaging.bandwidth.com/api/v2/users/1/media/real.png'] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(a_request(:get, provider_media_url).with(basic_auth: %w[1 1])).not_to have_been_made
      end

      it 'does not follow redirects on the credentialed request' do
        stub_request(:get, provider_media_url).to_return(status: 302, headers: { 'Location' => 'http://other.example/file.png' })
        redirected_request = stub_request(:get, 'http://other.example/file.png').to_return(status: 200, body: File.read('spec/assets/sample.png'))
        media_params = { 'media': [provider_media_url] }.with_indifferent_access

        expect do
          described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform
        end.to raise_error(Down::TooManyRedirects)
        expect(redirected_request).not_to have_been_requested
      end

      it 'does not fetch media that resolves to an internal address' do
        media_params = { 'media': ['http://internal.example/file.png'] }.with_indifferent_access

        described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform

        expect(sms_channel.inbox.messages.first.attachments.present?).to be false
      end

      it 'lets a transient download failure raise so the job retries' do
        stub_request(:get, 'http://other.example/file.png').to_return(status: 500)
        media_params = { 'media': ['http://other.example/file.png'] }.with_indifferent_access

        expect do
          described_class.new(inbox: sms_channel.inbox, params: params.merge(media_params)).perform
        end.to raise_error(SafeFetch::HttpError)
      end
    end
  end
end
