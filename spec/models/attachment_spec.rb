require 'rails_helper'

RSpec.describe Attachment do
  let!(:message) { create(:message) }

  describe 'external url validations' do
    let(:attachment) { message.attachments.new(account_id: message.account_id, file_type: :image) }

    before do
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
    end

    context 'when it validates external url length' do
      it 'valid when within limit' do
        attachment.external_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(attachment.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        attachment.external_url = 'a' * (Limits::URL_LENGTH_LIMIT + 5)
        attachment.valid?
        expect(attachment.errors[:external_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe 'download_url' do
    it 'returns valid download url' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.download_url).not_to be_nil
    end

    it 'normalizes audio/opus to audio/ogg in blob content_type' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
      attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'sample.ogg', content_type: 'audio/ogg')
      attachment.save!
      # Simulate Marcel detecting audio/opus
      attachment.file.blob.update_column(:content_type, 'audio/opus') # rubocop:disable Rails/SkipsModelValidations
      attachment.file.blob.reload

      expect(attachment.file.blob.content_type).to eq('audio/opus')
      attachment.download_url
      expect(attachment.file.blob.content_type).to eq('audio/ogg')
      expect(attachment.file.blob.reload.content_type).to eq('audio/ogg')
    end

    # A .opus file is an Ogg container like any other (RFC 7845), and audio/opus is what
    # Marcel answers once it is shown the name rather than anything it read in the file:
    # the same bytes come back audio/ogg when it is asked by content alone. WhatsApp Cloud
    # has no entry for audio/opus, so leaving it was a voice note answered with 131053.
    it 'normalizes audio/opus to audio/ogg for a .opus file too' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
      attachment.file.attach(io: Rails.root.join('spec/assets/sample.ogg').open, filename: 'voice.opus', content_type: 'audio/opus')
      attachment.save!

      attachment.download_url

      expect(attachment.file.blob.reload.content_type).to eq('audio/ogg')
    end

    # A blob stored before the identification was fixed still carries audio/opus on the object in
    # the bucket, and on GCS that is the type WhatsApp reads: the response-content-type override a
    # signed URL carries is ignored whenever the object's own metadata sets one. So correcting the
    # column is not enough, the object has to be rewritten.
    it 'rewrites the stored object when it normalizes a blob written before the fix' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
      attachment.file.attach(io: Rails.root.join('spec/assets/sample_opus.ogg').open, filename: 'voice.ogg', content_type: 'audio/ogg')
      attachment.save!
      attachment.file.blob.update_column(:content_type, 'audio/opus') # rubocop:disable Rails/SkipsModelValidations
      attachment.file.blob.reload
      rewritten = []
      allow(ActiveStorage::Blob.service).to receive(:update_metadata).and_wrap_original do |original, *args, **kwargs|
        rewritten << kwargs[:content_type]
        original.call(*args, **kwargs)
      end

      attachment.download_url

      expect(attachment.file.blob.reload.content_type).to eq('audio/ogg')
      expect(rewritten).to eq(['audio/ogg'])
    end

    it 'leaves an audio type it was not asked about alone' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :audio)
      attachment.file.attach(io: Rails.root.join('spec/assets/sample.mp3').open, filename: 'voice.mp3', content_type: 'audio/mpeg')
      attachment.save!

      attachment.download_url

      expect(attachment.file.blob.reload.content_type).to eq('audio/mpeg')
    end
  end

  describe 'with_attached_file?' do
    it 'returns true if its an attachment with file' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.with_attached_file?).to be true
    end

    it 'returns false if its an attachment with out a file' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :fallback)
      expect(attachment.with_attached_file?).to be false
    end
  end

  describe 'push_event_data for instagram story mentions' do
    let(:instagram_message) { create(:message, :instagram_story_mention) }

    before do
      # stubbing the request to facebook api during the message creation
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: 'http://graph.facebook.com/test-story-mention', id: '17920786367196703' } },
        from: { username: 'Sender-id-1', id: 'Sender-id-1' },
        id: 'instagram-message-id-1234'
      }.to_json, headers: {})
    end

    it 'returns original attachment url as data url if the message is outgoing' do
      message = create(:message, :instagram_story_mention, message_type: :outgoing)
      expect(message.attachments.first.push_event_data[:data_url]).not_to eq message.attachments.first.external_url
    end
  end

  # Chrome and Firefox play a `<video>` whose response says attachment; Safari does not, so
  # a video arrived in the dashboard as a file to download while the same code looked fine
  # to anyone testing in Chrome. Two halves are needed and neither works alone: an inline
  # URL, and the MIME on `content_types_allowed_inline`, without which ActiveStorage forces
  # the disposition back to attachment before signing.
  describe 'a video attachment' do
    let(:attachment) do
      message.attachments.new(account_id: message.account_id, file_type: :video).tap do |record|
        record.file.attach(io: Rails.root.join('spec/assets/sample.mp4').open, filename: 'sample.mp4',
                           content_type: 'video/mp4')
        record.save!
      end
    end

    it 'is served with a disposition the player can use' do
      expect(attachment.push_event_data[:data_url]).to match(/disposition=inline/)
    end

    # The half that lives in the initializer, and the one asking is not enough for: `Blob#url`
    # applies `forced_disposition_for_serving || disposition`, so a type outside the list is
    # served as an attachment however the caller asked for it. Read off the decision itself
    # rather than the signed URL, which the Disk service encodes the disposition inside. The
    # zip is the control: without it this passes on a build where nothing is ever forced.
    it 'is a type ActiveStorage agrees to serve inline' do
      zipped = message.attachments.new(account_id: message.account_id, file_type: :file)
      zipped.file.attach(io: Rails.root.join('spec/assets/sample.mp4').open, filename: 'archive.zip',
                         content_type: 'application/zip', identify: false)
      zipped.save!

      expect(attachment.file.blob.send(:forced_disposition_for_serving)).to be_nil
      expect(zipped.file.blob.send(:forced_disposition_for_serving)).to eq(:attachment)
    end

    it 'keeps the external address when we hold only a link' do
      linked = message.attachments.create!(account_id: message.account_id, file_type: :video,
                                           external_url: 'https://cdn.example.com/clip.mp4')

      expect(linked.push_event_data[:data_url]).to eq('https://cdn.example.com/clip.mp4')
    end

    # Meta serves these, so naming this deployment's storage would name a file that is not
    # there. `file_metadata` already decides that, and the inline URL must not undo it.
    it 'keeps Meta as the source for an Instagram incoming message' do
      instagram_inbox = create(:inbox, account: message.account,
                                       channel: create(:channel_instagram_fb_page, account: message.account,
                                                                                   instagram_id: 'instagram-video-test'))
      conversation = create(:conversation, account: message.account, inbox: instagram_inbox,
                                           additional_attributes: { 'type' => 'instagram_direct_message' })
      instagram_message = create(:message, account: message.account, inbox: instagram_inbox,
                                           conversation: conversation, message_type: :incoming)
      from_meta = instagram_message.attachments.new(account_id: message.account_id, file_type: :video,
                                                    external_url: 'https://instagram.com/clip.mp4')
      from_meta.file.attach(io: Rails.root.join('spec/assets/sample.mp4').open, filename: 'sample.mp4',
                            content_type: 'video/mp4')
      from_meta.save!

      expect(from_meta.push_event_data[:data_url]).to eq('https://instagram.com/clip.mp4')
    end
  end

  describe 'thumb_url' do
    it 'returns empty string for non-image attachments' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')

      expect(attachment.thumb_url).to eq('')
    end

    it 'generates thumb_url for image attachments' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: StringIO.new('fake image'), filename: 'test.jpg', content_type: 'image/jpeg')

      expect(attachment.thumb_url).to be_present
    end

    %w[image/bmp image/vnd.microsoft.icon image/vnd.adobe.photoshop].each do |content_type|
      it "preserves the original download without a thumbnail for #{content_type}" do
        attachment = message.attachments.create!(account_id: message.account_id, file_type: :image)
        attachment.file.attach(
          io: StringIO.new('original image'), filename: 'image', content_type: content_type, identify: false
        )

        expect(attachment.thumb_url).to eq('')
        expect(attachment.file_url).to be_present
        expect(attachment.file.download).to eq('original image')
      end
    end

    it 'handles unrepresentable images gracefully' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: StringIO.new('fake image'), filename: 'test.jpg', content_type: 'image/jpeg')

      allow(attachment.file).to receive(:representation).and_raise(ActiveStorage::UnrepresentableError.new('Cannot represent'))

      expect(Rails.logger).to receive(:warn).with(/Unrepresentable image attachment: #{attachment.id}/)
      expect(attachment.thumb_url).to eq('')
    end
  end

  describe 'meta data handling' do
    let(:message) { create(:message) }

    context 'when attachment is a contact type' do
      let(:contact_attachment) do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: :contact,
          fallback_title: '+1234567890',
          meta: {
            first_name: 'John',
            last_name: 'Doe'
          }
        )
      end

      it 'stores and retrieves meta data correctly' do
        expect(contact_attachment.meta['first_name']).to eq('John')
        expect(contact_attachment.meta['last_name']).to eq('Doe')
      end

      it 'includes meta data in push_event_data' do
        event_data = contact_attachment.push_event_data
        expect(event_data[:meta]).to eq({
                                          'first_name' => 'John',
                                          'last_name' => 'Doe'
                                        })
      end

      it 'returns empty hash for meta if not set' do
        attachment = message.attachments.create!(
          account_id: message.account_id,
          file_type: :contact,
          fallback_title: '+1234567890'
        )
        expect(attachment.push_event_data[:meta]).to eq({})
      end
    end

    context 'when meta is used with other file types' do
      let(:image_attachment) do
        attachment = message.attachments.new(
          account_id: message.account_id,
          file_type: :image,
          meta: { description: 'Test image' }
        )
        attachment.file.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
        attachment.save!
        attachment
      end

      it 'preserves meta data with file attachments' do
        expect(image_attachment.meta['description']).to eq('Test image')
        expect(image_attachment.file.filename.to_s).to eq('avatar.png')
        expect(image_attachment.file.content_type).to eq('image/png')
      end
    end
  end

  describe 'push_event_data for instagram direct message attachments' do
    let(:account) { create(:account) }
    let(:instagram_inbox) do
      create(:inbox, account: message.account,
                     channel: create(:channel_instagram_fb_page, account: account, instagram_id: 'instagram-dm-test'))
    end

    context 'when conversation type is instagram_direct_message' do
      let(:conversation) do
        create(:conversation, account: message.account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'instagram_direct_message' })
      end
      let(:instagram_message) do
        create(:message, account: message.account, inbox: instagram_inbox, conversation: conversation, message_type: :incoming)
      end

      it 'uses external_url for data_url and thumb_url' do
        attachment = instagram_message.attachments.new(account_id: message.account_id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).to eq('https://instagram.com/image.jpg')
        expect(event_data[:thumb_url]).to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when conversation type is not instagram_direct_message' do
      let(:conversation) do
        create(:conversation, account: message.account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'other_type' })
      end
      let(:instagram_message) do
        create(:message, account: message.account, inbox: instagram_inbox, conversation: conversation, message_type: :incoming)
      end

      it 'uses file_url for data_url instead of external_url' do
        attachment = instagram_message.attachments.new(account_id: message.account_id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).not_to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when message is outgoing on instagram DM conversation' do
      let(:conversation) do
        create(:conversation, account: message.account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'instagram_direct_message' })
      end
      let(:outgoing_message) do
        create(:message, account: message.account, inbox: instagram_inbox, conversation: conversation, message_type: :outgoing)
      end

      it 'does not override data_url with external_url' do
        attachment = outgoing_message.attachments.new(account_id: message.account_id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).not_to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when inbox is Channel::Instagram (direct login)' do
      let(:instagram_channel) { create(:channel_instagram, account: account) }
      let(:direct_inbox) { instagram_channel.inbox }
      let(:conversation) { create(:conversation, account: message.account, inbox: direct_inbox) }
      let(:incoming_message) { create(:message, account: message.account, inbox: direct_inbox, conversation: conversation, message_type: :incoming) }

      it 'uses external_url for data_url and thumb_url' do
        attachment = incoming_message.attachments.new(account_id: message.account_id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).to eq('https://instagram.com/image.jpg')
        expect(event_data[:thumb_url]).to eq('https://instagram.com/image.jpg')
      end
    end
  end

  describe 'push_event_data for ig_reel attachments' do
    it 'returns external_url as data_url when no file is attached' do
      attachment = message.attachments.create!(
        account_id: message.account_id,
        file_type: :ig_reel,
        external_url: 'https://www.facebook.com/reel/123456'
      )

      event_data = attachment.push_event_data
      expect(event_data[:data_url]).to eq('https://www.facebook.com/reel/123456')
      expect(event_data[:thumb_url]).to eq('')
    end

    it 'returns file_url as data_url when file is attached' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :ig_reel,
                                           external_url: 'https://www.instagram.com/reel/123')
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!

      event_data = attachment.push_event_data
      expect(event_data[:data_url]).to be_present
    end
  end

  describe 'push_event_data for audio attachments' do
    let(:attachment) { message.attachments.new(account_id: message.account_id, file_type: :audio) }

    before do
      attachment.file.attach(io: StringIO.new('fake audio'), filename: 'voice.ogg', content_type: 'audio/ogg')
      attachment.save!
    end

    it 'honours resolve_model_to_route when the proxy route is configured' do
      allow(ActiveStorage).to receive(:resolve_model_to_route).and_return(:rails_storage_proxy)

      expect(attachment.push_event_data[:data_url]).to include('/rails/active_storage/blobs/proxy/')
    end
  end

  describe 'push_event_data for embed attachments' do
    it 'returns external url as data_url' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :embed, external_url: 'https://example.com/embed')

      expect(attachment.push_event_data[:data_url]).to eq('https://example.com/embed')
    end
  end

  describe 'set_extension' do
    it 'sets extension from filename on save' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      expect(attachment.extension).to eq('pdf')
    end

    it 'does not overwrite extension if already set' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file, extension: 'doc')
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      expect(attachment.extension).to eq('doc')
    end

    it 'handles filenames without extension' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake data'), filename: 'README', content_type: 'text/plain')
      attachment.save!

      expect(attachment.extension).to be_nil
    end
  end

  describe 'push_event_data includes extension and content_type' do
    it 'returns extension and content_type for file attachments' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      event_data = attachment.push_event_data
      expect(event_data[:extension]).to eq('pdf')
      expect(event_data[:content_type]).to eq('application/pdf')
    end
  end

  describe 'file size validation' do
    let(:attachment) { message.attachments.new(account_id: message.account_id, file_type: :image) }

    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
    end

    it 'respects configured limit' do
      allow(GlobalConfigService).to receive(:load)
        .with('MAXIMUM_FILE_UPLOAD_SIZE', 40)
        .and_return('5')

      attachment.errors.clear
      attachment.send(:validate_file_size, 4.megabytes)

      expect(attachment.errors[:file]).to be_empty

      attachment.errors.clear
      attachment.send(:validate_file_size, 6.megabytes)

      expect(attachment.errors[:file]).to include('size is too big')
    end

    # The size validation only runs on a web widget inbox, so nothing was checking a file on a
    # WhatsApp one. A zero-byte recording was accepted, stored and sent to the provider as a voice
    # note: the agent saw a message that looked sent, and the rejection arrived later as a failed
    # status carrying an error nobody could tie back to "the file was empty".
    describe 'an empty file' do
      def empty_attachment_on(channel, message_type: :outgoing, refuse: true)
        inbox = create(:inbox, account: message.account, channel: channel)
        conversation = create(:conversation, account: message.account, inbox: inbox)
        owner = create(:message, account: message.account, conversation: conversation, message_type: message_type)
        attachment = owner.attachments.new(account_id: message.account_id, file_type: :audio, refuse_empty_file: refuse)
        attachment.file.attach(io: StringIO.new(''), filename: 'voice.ogg', content_type: 'audio/ogg')
        attachment
      end

      def whatsapp_channel
        create(:channel_whatsapp, account: message.account, validate_provider_config: false, sync_templates: false)
      end

      it 'is rejected on a provider inbox, where nothing used to look' do
        attachment = empty_attachment_on(whatsapp_channel)

        expect(attachment).not_to be_valid
        expect(attachment.errors[:file]).to include('is empty')
      end

      it 'is rejected on a web widget inbox too' do
        attachment = empty_attachment_on(create(:channel_widget, account: message.account))

        expect(attachment).not_to be_valid
        expect(attachment.errors[:file]).to include('is empty')
      end

      it 'is rejected on a template message too' do
        attachment = empty_attachment_on(whatsapp_channel, message_type: :template)

        expect(attachment).not_to be_valid
        expect(attachment.errors[:file]).to include('is empty')
      end

      it 'leaves a file with bytes alone' do
        inbox = create(:inbox, account: message.account, channel: whatsapp_channel)
        conversation = create(:conversation, account: message.account, inbox: inbox)
        sized_message = create(:message, account: message.account, conversation: conversation, message_type: :outgoing)
        attachment = sized_message.attachments.new(account_id: message.account_id, file_type: :audio, refuse_empty_file: true)
        attachment.file.attach(io: Rails.root.join('spec/assets/sample_opus.ogg').open, filename: 'voice.ogg', content_type: 'audio/ogg')

        expect(attachment).to be_valid
      end

      # The refusal is off unless the caller asks for it. Every provider ingestion path builds
      # attachments without asking, so an empty download is stored rather than raising inside the
      # webhook and losing the message. This holds for an incoming message and for an echo alike,
      # which is why neither needs its own marker here.
      it 'is accepted by default, because ingestion never asks to refuse' do
        attachment = empty_attachment_on(whatsapp_channel, refuse: false)

        expect(attachment).to be_valid
      end

      it 'is accepted by default on an incoming message too' do
        attachment = empty_attachment_on(whatsapp_channel, message_type: :incoming, refuse: false)

        expect(attachment).to be_valid
      end

      # The flag is in-memory only, so a row that already exists is never re-refused when something
      # saves it again later. Retry does exactly that: it calls `message.update!` on a failed
      # message, and an attachment stored before this validation existed must not block it.
      it 'never refuses a row that is already stored, however it is saved again' do
        attachment = empty_attachment_on(whatsapp_channel, refuse: false)
        attachment.save!
        owner = attachment.message

        # A fresh instance, because `reload` keeps the in-memory accessor on the object it is
        # called on and would hide exactly the thing under test.
        expect(described_class.find(attachment.id).refuse_empty_file).to be_nil
        expect { owner.update!(content: 'edited') }.not_to raise_error
        expect(described_class.find(attachment.id)).to be_valid
      end

      # A fence, not a checklist. There are four provider ingestion paths that build outgoing
      # attachments (baileys, z-api, the session writer, the reaction store), each marking the
      # echo differently, and enumerating them is how the third one got missed. Assert instead
      # that composing a message is the only thing in the tree that turns the refusal on.
      it 'is turned on in exactly one place in the source tree' do
        roots = %w[app enterprise lib].select { |dir| Rails.root.join(dir).directory? }
        setters = Dir.glob(Rails.root.join("{#{roots.join(',')}}/**/*.rb")).select do |path|
          File.read(path).match?(/refuse_empty_file\s*[:=]/)
        end

        expect(setters.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s })
          .to contain_exactly('app/builders/messages/message_builder.rb')
      end

      # On a message that asked to refuse, so the `file.attached?` guard is what keeps this valid
      # rather than the flag short-circuiting before the file is ever looked at.
      it 'leaves an attachment that carries no file at all alone' do
        outgoing = create(:message, account: message.account, conversation: message.conversation, message_type: :outgoing)
        location = outgoing.attachments.new(account_id: message.account_id, file_type: :location, refuse_empty_file: true,
                                            coordinates_lat: 1.0, coordinates_long: 1.0, fallback_title: 'here')

        expect(location).to be_valid
      end
    end

    it 'falls back to default when configured limit is invalid' do
      allow(GlobalConfigService).to receive(:load)
        .with('MAXIMUM_FILE_UPLOAD_SIZE', 40)
        .and_return('-10')

      attachment.errors.clear
      attachment.send(:validate_file_size, 41.megabytes)

      expect(attachment.errors[:file]).to include('size is too big')
    end
  end
end
