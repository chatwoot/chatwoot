require 'rails_helper'

describe Messages::MessageBuilder do
  subject(:message_builder) { described_class.new(user, conversation, params).perform }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:inbox_member) { create(:inbox_member, inbox: inbox, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let(:message_for_reply) { create(:message, conversation: conversation) }
  let(:params) do
    ActionController::Parameters.new({
                                       content: 'test'
                                     })
  end

  describe '#perform' do
    it 'creates a message' do
      message = message_builder
      expect(message.content).to eq params[:content]
    end
  end

  # message_type is an enum on Message, so `message_type: :incoming` is the shape the rest of the
  # codebase writes. The builder decides who the sender is, whether the inbox may take incoming
  # messages and whether to render the e-mail body by comparing against Strings, so a Symbol has to
  # land on the same decisions as its String.
  describe 'when message_type arrives as a Symbol' do
    let(:contact) { create(:contact, account: account, name: 'John', email: 'john@example.com') }
    let(:conversation) { create(:conversation, inbox: inbox, account: account, contact: contact) }

    it 'refuses an incoming message outside an API inbox, like the String does' do
      expect { described_class.new(user, conversation, { content: 'test', message_type: :incoming }).perform }
        .to raise_error 'Incoming messages are only allowed in Api inboxes'
      expect(conversation.messages.where(content: 'test')).to be_empty
    end

    it 'saves an outgoing message with the user as sender, like the String does' do
      message = described_class.new(user, conversation, { content: 'test', message_type: :outgoing }).perform

      expect(message).to be_outgoing
      expect(message.sender).to eq(user)
    end

    it 'renders the e-mail body of an outgoing message, like the String does' do
      email_conversation = create(:conversation, inbox: create(:channel_email, account: account).inbox, account: account, contact: contact)

      message = described_class.new(user, email_conversation, { content: 'Hello {{contact.name}}', message_type: :outgoing }).perform

      expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello John'
    end
  end

  # A template is sent from the agent side, like an outgoing message: the builder already renders its
  # e-mail body for that reason, and the sender has to agree, or the conversation shows it as written by
  # the contact and the mailer, which reads the sender's name, fails to send it.
  describe 'when message_type is template' do
    let(:user) { create(:user, account: account, name: 'Agent Smith') }
    let(:contact) { create(:contact, account: account, name: 'John', email: 'john@example.com') }
    let(:conversation) do
      create(:conversation, inbox: create(:channel_email, account: account).inbox, account: account, contact: contact)
    end

    it 'saves the user as sender, like an outgoing message' do
      message = described_class.new(user, conversation, { content: 'test', message_type: 'template' }).perform

      expect(message).to be_template
      expect(message.sender).to eq(user)
    end

    it 'renders the agent in the e-mail body as the user, not the contact' do
      message = described_class.new(user, conversation, { content: 'Hi, {{agent.name}} here', message_type: 'template' }).perform

      expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hi, Agent Smith here'
    end

    it 'keeps the contact as sender of an incoming message' do
      api_conversation = create(:conversation, inbox: create(:channel_api, account: account).inbox, account: account, contact: contact)

      message = described_class.new(user, api_conversation, { content: 'test', message_type: 'incoming' }).perform

      expect(message.sender).to eq(contact)
    end
  end

  # An activity is a system line, like the ones Chatwoot writes for a status or an assignment, so
  # the contact did not write it: with the contact as sender, saving it marked them as active.
  describe 'when message_type is activity' do
    let(:contact) { create(:contact, account: account, last_activity_at: 3.days.ago) }
    let(:conversation) { create(:conversation, inbox: inbox, account: account, contact: contact) }

    it 'saves it with no sender and leaves the contact last activity where it was' do
      message = nil

      expect { message = described_class.new(user, conversation, { content: 'Order shipped', message_type: 'activity' }).perform }
        .not_to(change { contact.reload.last_activity_at })
      expect(message).to be_activity
      expect(message.sender).to be_nil
    end

    it 'does not take the bot a caller names as sender either' do
      params = { content: 'Order shipped', message_type: 'activity', sender_type: 'AgentBot', sender_id: create(:agent_bot).id }

      expect(described_class.new(user, conversation, params).perform.sender).to be_nil
    end
  end

  describe '#content_attributes' do
    context 'when content_attributes is a JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: "{\"in_reply_to\":#{message_for_reply.id}}"
                                         })
      end

      it 'parses content_attributes from JSON string' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is a hash' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: { in_reply_to: message_for_reply.id }
                                         })
      end

      it 'uses content_attributes as provided' do
        message = described_class.new(user, conversation, params).perform
        expect(message.content_attributes).to include(in_reply_to: message_for_reply.id)
      end
    end

    context 'when content_attributes is absent' do
      let(:params) do
        ActionController::Parameters.new({ content: 'test' })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is nil' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: nil
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end

    context 'when content_attributes is an invalid JSON string' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           content_attributes: 'invalid_json'
                                         })
      end

      it 'defaults to an empty hash' do
        message = message_builder
        expect(message.content_attributes).to eq({})
      end
    end
  end

  describe '#perform when message_type is incoming' do
    context 'when channel is not api' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates throws error when channel is not api' do
        expect { message_builder }.to raise_error 'Incoming messages are only allowed in Api inboxes'
      end
    end

    context 'when channel is api' do
      let(:channel_api) { create(:channel_api, account: account) }
      let(:conversation) { create(:conversation, inbox: channel_api.inbox, account: account) }
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           message_type: 'incoming'
                                         })
      end

      it 'creates message when channel is api' do
        message = message_builder
        expect(message.message_type).to eq params[:message_type]
      end

      # An API inbox pushes customer messages through this same builder, so it is ingestion even
      # though it comes in over HTTP. Refusing an empty attachment here would answer 422 and throw
      # away the message text with it.
      it 'keeps an empty attachment on an incoming message instead of refusing the whole message' do
        params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/attachment.pdf', 'application/pdf')]

        message = message_builder

        expect(message.attachments.first.refuse_empty_file).to be(false)
        expect(message.attachments.first.file.byte_size).to eq(0)
      end
    end

    context 'when attachment messages' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]
                                         })
      end

      it 'creates message with attachments' do
        message = message_builder
        expect(message.attachments.first.file_type).to eq 'image'
      end

      # This builder is the boundary where an agent (or a campaign, macro or automation) composes
      # a message we are about to send. It is the only place that asks the attachment to refuse an
      # empty file, so a zero-byte upload is named here instead of failing at the provider later.
      it 'asks the attachment to refuse an empty file' do
        message = message_builder
        expect(message.attachments.first.refuse_empty_file).to be(true)
      end

      it 'refuses a zero-byte upload instead of storing it' do
        params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/attachment.pdf', 'application/pdf')]

        expect { message_builder }.to raise_error(ActiveRecord::RecordInvalid, /file is empty/i)
        expect(Message.count).to eq(0)
      end

      it 'creates attachment with is_recorded_audio metadata' do
        params[:is_recorded_audio] = true

        message = message_builder

        expect(message.attachments.first.meta).to eq({ 'is_recorded_audio' => true })
      end

      it 'creates attachment with is_recorded_audio metadata when param is array of filenames' do
        params[:is_recorded_audio] = ['avatar.png']

        message = message_builder

        expect(message.attachments.first.meta).to eq({ 'is_recorded_audio' => true })
      end

      it 'creates attachment with is_recorded_audio metadata when param is string with array' do
        params[:is_recorded_audio] = '["avatar.png"]'

        message = message_builder

        expect(message.attachments.first.meta).to eq({ 'is_recorded_audio' => true })
      end

      # A multipart request carries every value as a string, so `is_voice_message=false` arrives as
      # the string "false", which is `present?` and reads as an explicit yes at both providers.
      # The sibling top-level parameter is already cast one line away; this one was not.
      it 'casts a boolean metadata flag sent as a string' do
        params[:attachments_metadata] = { 'avatar.png' => { is_voice_message: 'false', is_recorded_audio: 'false' } }

        message = message_builder

        expect(message.attachments.first.meta)
          .to include('is_voice_message' => false, 'is_recorded_audio' => false)
      end

      it 'casts a boolean metadata flag sent as the string true' do
        params[:attachments_metadata] = { 'avatar.png' => { is_voice_message: 'true' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('is_voice_message' => true)
      end

      # The case that separates casting the value from dropping the key, and the only one that
      # does. The per-attachment metadata merges over the top-level flag, so a cast `false` wins
      # and the note goes out silent. Dropping the key instead would leave the top-level `true`
      # standing alone and send it as a voice note, which is the opposite of what was asked.
      it 'lets a per-attachment refusal beat the top-level flag' do
        params[:is_recorded_audio] = true
        params[:attachments_metadata] = { 'avatar.png' => { is_recorded_audio: 'false' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('is_recorded_audio' => false)
      end

      # The same sentence for the sibling flag, and it was not true for it. `tag_voice_message` ran
      # after the metadata merge and wrote `true` over the refusal that had just been read and cast,
      # so the two flags disagreed about who wins with nothing saying so. An audio attachment,
      # because the top-level flag only reaches one.
      it 'lets a per-attachment refusal beat the top-level voice flag too' do
        params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]
        params[:is_voice_message] = true
        params[:attachments_metadata] = { 'sample.mp3' => { is_voice_message: 'false' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('is_voice_message' => false)
      end

      # Mentioning the key is answering, whatever the answer is. An explicit null is the case that
      # separates "the entry has an opinion" from "the entry refuses", and it goes the same way as
      # the sibling flag: there the entry merges last, so a null lands on top of the message-level
      # value. Reading only a `false` here would put the two flags back out of step on exactly the
      # input nobody thinks about.
      it 'treats an explicit null in the entry as the entry having answered' do
        params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]
        params[:is_voice_message] = true
        params[:attachments_metadata] = { 'sample.mp3' => { is_voice_message: nil } }

        message = message_builder

        expect(message.attachments.first.meta['is_voice_message']).to be_nil
      end

      # And the top-level flag still reaches an attachment whose metadata says nothing about it,
      # which is the case the dashboard sends: one recording, the flag on the message.
      it 'still tags an attachment whose metadata does not mention the voice flag' do
        params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]
        params[:is_voice_message] = true
        params[:attachments_metadata] = { 'sample.mp3' => { description: 'recado' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('is_voice_message' => true, 'description' => 'recado')
      end

      # A video note is asked for the way a voice note is: on the message for the one file a caller
      # sends, or per file. The note is what the native channel sends as a circle, so a missed tag
      # is a rectangle on the customer's phone and a stray one is a circle nobody asked for.
      describe 'a video note' do
        let(:video) { Rack::Test::UploadedFile.new('spec/assets/sample.mp4', 'video/mp4') }
        let(:native) { create(:channel_whatsapp, account: account, provider: 'native', validate_provider_config: false, sync_templates: false) }
        let(:inbox) { native.inbox }

        # The context sends a text with its file, and a note goes out without one.
        before do
          params[:attachments] = [video]
          params.delete(:content)
        end

        it 'tags the video when the message asks for one' do
          params[:is_video_note] = 'true'

          expect(message_builder.attachments.first.meta).to include('is_video_note' => true)
        end

        it 'leaves the video alone when a multipart request says false' do
          params[:is_video_note] = 'false'

          expect(message_builder.attachments.first.meta.to_h).not_to include('is_video_note' => true)
        end

        it 'lets a per-file refusal beat the flag on the message' do
          params[:is_video_note] = 'true'
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'false' } }

          expect(message_builder.attachments.first.meta).to include('is_video_note' => false)
        end

        it 'casts a per-file yes sent as a string' do
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true' } }

          expect(message_builder.attachments.first.meta).to include('is_video_note' => true)
        end

        it 'does not tag a file that is not a video' do
          params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]
          params[:is_video_note] = 'true'

          expect(message_builder.attachments.first.meta.to_h).not_to have_key('is_video_note')
        end

        # The circle has nowhere to show a caption and the connector refuses one, so the text would
        # turn the message red after it was created. Refused here, before anything is stored.
        it 'refuses text sent with the note, and stores nothing' do
          params[:is_video_note] = 'true'
          params[:content] = 'legenda'

          expect { message_builder }.to raise_error(ActiveRecord::RecordInvalid, /no text/)
          expect(conversation.messages.count).to eq(0)
        end

        # The native channel sends the first file of a message and nothing else, so a note behind a
        # picture would be stored, reported as sent, and never reach the phone.
        it 'refuses a note that travels with another file' do
          params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png'), video]
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true' } }

          expect { message_builder }.to raise_error(ActiveRecord::RecordInvalid, /goes alone/)
          expect(conversation.messages.count).to eq(0)
        end

        # Blank to Rails and still a body to the dashboard, which would draw it as a rectangle.
        it 'refuses a blank text sent with the note' do
          params[:is_video_note] = 'true'
          params[:content] = ' '

          expect { message_builder }.to raise_error(ActiveRecord::RecordInvalid, /no text/)
        end

        # A survey sends its text and link as the caption even with no content of its own.
        it 'refuses a survey sent as a note' do
          params[:is_video_note] = 'true'
          params[:content_type] = 'input_csat'

          expect { message_builder }.to raise_error(ActiveRecord::RecordInvalid, /no text/)
        end

        # An API inbox ingesting a note somebody recorded keeps it a note: the rule about where a note
        # can go out is about sending, not about what arrives.
        it 'keeps the mark on an incoming note through an API inbox' do
          api = create(:channel_api, account: account).inbox
          incoming = create(:conversation, account: account, inbox: api)
          params[:message_type] = 'incoming'
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: true } }

          meta = described_class.new(user, incoming, params).perform.attachments.first.meta

          expect(meta).to include('is_video_note' => true)
        end

        # An integration recording a note it already sent elsewhere: the API inbox delivers nothing
        # itself, so the mark is a record of what went out, not a request.
        it 'keeps the mark on an outgoing note recorded through an API inbox' do
          api = create(:channel_api, account: account).inbox
          recorded = create(:conversation, account: account, inbox: api)
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true' } }

          meta = described_class.new(user, recorded, params).perform.attachments.first.meta

          expect(meta).to include('is_video_note' => true)
        end

        # The one-file and no-text rules are the native connector's. A record of what already went out
        # elsewhere is kept in whatever shape it went.
        it 'records a note sent elsewhere with text and another file through an API inbox' do
          api = create(:channel_api, account: account).inbox
          recorded = create(:conversation, account: account, inbox: api)
          params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png'), video]
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true' } }
          params[:content] = 'enviado pelo celular'

          message = described_class.new(user, recorded, params).perform

          expect(message.attachments.map { |attachment| attachment.meta.to_h['is_video_note'] }).to eq([nil, true])
        end

        it 'does not tag a private note even when it says it came in' do
          api = create(:channel_api, account: account).inbox
          incoming = create(:conversation, account: account, inbox: api)
          params[:message_type] = 'incoming'
          params[:private] = 'true'
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: true } }

          meta = described_class.new(user, incoming, params).perform.attachments.first.meta.to_h

          expect(meta).not_to have_key('is_video_note')
        end

        # Already sent from the phone and recorded with its WhatsApp id, so the send job skips it and
        # the connector's rules have nothing to protect.
        it 'records a note that already went out with its WhatsApp id' do
          params[:is_video_note] = 'true'
          params[:content] = 'enviado pelo celular'
          params[:source_id] = '3EB0A1B2C3D4E5F60742'

          expect(message_builder.attachments.first.meta).to include('is_video_note' => true)
        end

        # Recorded with its WhatsApp id on a provider that could not have sent it as a note: the
        # phone did, and the record keeps saying so.
        it 'keeps the mark on a note recorded with its WhatsApp id on another provider' do
          uazapi = create(:channel_whatsapp, account: account, provider: 'uazapi', validate_provider_config: false,
                                             sync_templates: false)
          recorded = create(:conversation, account: account, inbox: uazapi.inbox)
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true' } }
          params[:source_id] = '3EB0A1B2C3D4E5F60743'

          meta = described_class.new(user, recorded, params).perform.attachments.first.meta

          expect(meta).to include('is_video_note' => true)
        end

        # A private note never leaves, so there is no circle to send and no caption to refuse.
        it 'does not tag a private note, and keeps its text' do
          params[:is_video_note] = 'true'
          params[:private] = 'true'
          params[:content] = 'para o time'

          expect(message_builder.attachments.first.meta.to_h).not_to have_key('is_video_note')
        end

        # Uazapi sends the same request as an ordinary video, so a circle in the dashboard would be a
        # promise the phone does not keep. Dropped from the per-file entry as well as the message.
        it 'does not tag a video on an inbox that cannot send a note' do
          uazapi = create(:channel_whatsapp, account: account, provider: 'uazapi', validate_provider_config: false,
                                             sync_templates: false)
          other = create(:conversation, account: account, inbox: uazapi.inbox)
          params[:is_video_note] = 'true'
          params[:attachments_metadata] = { 'sample.mp4' => { is_video_note: 'true', description: 'recado' } }

          meta = described_class.new(user, other, params).perform.attachments.first.meta.to_h

          expect(meta).to eq('description' => 'recado')
        end
      end

      # What the cast covers is `ActiveModel::Type::Boolean`'s own list, and no more. Widening it
      # would be inventing a second truth table one line from the sibling parameter that uses the
      # standard one, which is the inconsistency this exists to remove.
      it 'turns the flag off for every value Rails treats as false' do
        %w[false FALSE 0 off f].each do |falsey|
          params[:attachments_metadata] = { 'avatar.png' => { is_voice_message: falsey } }

          expect(described_class.new(user, conversation, params).perform.attachments.first.meta)
            .to include('is_voice_message' => false), "expected #{falsey.inspect} to turn the flag off"
        end
      end

      # Measured, not aspired to: `no` is not on that list, so it still reads as a yes. Anyone who
      # wants it to stop has to change the truth table, not this cast.
      it 'still reads a value Rails does not know as a yes' do
        params[:attachments_metadata] = { 'avatar.png' => { is_voice_message: 'no' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('is_voice_message' => true)
      end

      # Only the flags that are booleans. Everything else a caller sends is theirs.
      it 'leaves other metadata values exactly as they were sent' do
        params[:attachments_metadata] = { 'avatar.png' => { description: 'false', source: '0' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('description' => 'false', 'source' => '0')
      end

      it 'creates attachment with custom metadata from attachments_metadata param' do
        params[:attachments_metadata] = { 'avatar.png' => { description: 'Profile picture', source: 'upload' } }

        message = message_builder

        expect(message.attachments.first.meta).to include('description' => 'Profile picture', 'source' => 'upload')
      end

      # `to_h` answers a different exception for each shape a caller can put at a value
      # position -- NoMethodError for a String or a number, TypeError for a bare array,
      # ArgumentError for an array of short pairs -- and each of them took the whole request
      # down and put the Ruby text in the HTTP body. Ignoring the entry keeps the message and
      # the attachment, which is what the caller was asking for.
      [['a String', 'lixo'], ['a number', 5], ['a bare array', %w[a b]], ['an array of short pairs', [['a']]]].each do |shape, value|
        it "ignores metadata sent as #{shape}, and still creates the message and the attachment" do
          params[:attachments_metadata] = { 'avatar.png' => value }

          message = message_builder

          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.meta).to eq({})
        end
      end

      # The one shape `to_h` accepts, and the reason ignoring beats coercing: an array of pairs
      # became metadata whose `is_voice_message` was the string "false", which is `present?` and
      # reads at both providers as an explicit yes. `cast_metadata_flags` never saw it, because
      # it only casts inside a Hash.
      it 'does not turn an array of pairs into metadata with a string boolean' do
        params[:attachments_metadata] = { 'avatar.png' => [%w[is_voice_message false], %w[description legenda]] }

        message = message_builder

        expect(message.attachments.first.meta['is_voice_message']).not_to eq('false')
        expect(message.attachments.first.meta).to eq({})
      end

      it 'says in the log which file had its metadata ignored, and what arrived' do
        allow(Rails.logger).to receive(:warn)
        params[:attachments_metadata] = { 'avatar.png' => 'lixo' }

        message_builder

        expect(Rails.logger).to have_received(:warn).with(/avatar\.png.*String/)
      end

      # The other place the same value can arrive, and it died earlier: `attachments_metadata=lixo`
      # never reached an attachment at all, it broke on `deep_stringify_keys`.
      [['a String', 'lixo'], ['an array', %w[a]]].each do |shape, value|
        it "ignores attachments_metadata sent as #{shape} at the top level" do
          params[:attachments_metadata] = value

          message = message_builder

          expect(message.attachments.count).to eq(1)
          expect(message.attachments.first.meta).to eq({})
        end
      end

      it 'does not apply metadata when filename key does not match' do
        params[:attachments_metadata] = { 'other_file.png' => { description: 'Wrong file' } }

        message = message_builder

        expect(message.attachments.first.meta).to eq({})
      end

      it 'merges is_recorded_audio with attachments_metadata' do
        params[:is_recorded_audio] = true
        params[:attachments_metadata] = { 'avatar.png' => { description: 'Audio note' } }

        message = message_builder

        expect(message.attachments.first.meta).to eq({
                                                       'is_recorded_audio' => true,
                                                       'description' => 'Audio note'
                                                     })
      end

      context 'when transcode_audio is set' do
        let(:params) do
          ActionController::Parameters.new({
                                             content: 'test',
                                             transcode_audio: 'opus',
                                             attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]
                                           })
        end

        it 'transcodes audio attachment and sets is_recorded_audio metadata' do
          service_instance = instance_double(Audio::TranscodeService)
          allow(Audio::TranscodeService).to receive(:new).and_return(service_instance)
          allow(service_instance).to receive(:perform)

          message = message_builder

          expect(Audio::TranscodeService).to have_received(:new)
          expect(service_instance).to have_received(:perform)
          expect(message.attachments.first.meta).to include('is_recorded_audio' => true)
        end

        it 'does not transcode non-audio attachments' do
          allow(Audio::TranscodeService).to receive(:new)
          params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]

          message = message_builder

          expect(Audio::TranscodeService).not_to have_received(:new)
          expect(message.attachments.first.file_type).to eq 'image'
        end
      end

      context 'when transcode_audio is not set' do
        it 'does not invoke transcoding service' do
          allow(Audio::TranscodeService).to receive(:new)
          params[:attachments] = [Rack::Test::UploadedFile.new('spec/assets/sample.mp3', 'audio/mpeg')]

          message = message_builder

          expect(Audio::TranscodeService).not_to have_received(:new)
          expect(message.attachments.first.file_type).to eq 'audio'
        end
      end

      context 'when DIRECT_UPLOAD_ENABLED' do
        let(:params) do
          ActionController::Parameters.new({
                                             content: 'test',
                                             attachments: [get_blob_for('spec/assets/avatar.png', 'image/png').signed_id]
                                           })
        end

        it 'creates message with attachments' do
          message = message_builder
          expect(message.attachments.first.file_type).to eq 'image'
        end

        # A direct upload sends an ActiveStorage signed ID, which is a String, and a String has no
        # `original_filename`. The per-attachment metadata is keyed off that name, so the whole of
        # `attachments_metadata` was dropped on this path, silently, with a 200 and a stored message.
        it 'applies the per-attachment metadata, which is keyed off a name a signed ID also has' do
          params[:attachments_metadata] = { 'avatar.png' => { description: 'legenda' } }

          message = message_builder

          expect(message.attachments.first.meta).to include('description' => 'legenda')
        end

        # Worse than losing metadata: losing a refusal. The top-level `is_recorded_audio` is merged
        # first and the per-attachment entry merges over it, so a caller saying "not this one" was
        # honoured on multipart and ignored here, where the entry never arrived.
        it 'lets a per-attachment refusal beat the top-level flag, as multipart does' do
          params[:attachments] = [get_blob_for('spec/assets/sample.ogg', 'audio/ogg').signed_id]
          params[:is_recorded_audio] = true
          params[:attachments_metadata] = { 'sample.ogg' => { is_recorded_audio: 'false' } }

          message = message_builder

          expect(message.attachments.first.meta).to include('is_recorded_audio' => false)
        end

        # Same sentence for the voice flag, measured here too rather than inferred from multipart:
        # the defect was in `tag_voice_message`, which both upload paths run, so both wrote `true`
        # over the refusal.
        it 'lets a per-attachment refusal beat the top-level voice flag, as multipart does' do
          params[:attachments] = [get_blob_for('spec/assets/sample.ogg', 'audio/ogg').signed_id]
          params[:is_voice_message] = true
          params[:attachments_metadata] = { 'sample.ogg' => { is_voice_message: 'false' } }

          message = message_builder

          expect(message.attachments.first.meta).to include('is_voice_message' => false)
        end

        # The sibling reader in the same `process_metadata` has no `respond_to?` guard at all, so
        # this raised `NoMethodError` for a String and the request answered 422 with nothing stored.
        it 'reads the recorded-audio file list instead of raising on a signed ID' do
          params[:attachments] = [get_blob_for('spec/assets/sample.ogg', 'audio/ogg').signed_id]
          params[:is_recorded_audio] = ['sample.ogg']

          message = message_builder

          expect(message.attachments.first.meta).to include('is_recorded_audio' => true)
        end

        it 'reads the recorded-audio list sent as a JSON string too' do
          params[:attachments] = [get_blob_for('spec/assets/sample.ogg', 'audio/ogg').signed_id]
          params[:is_recorded_audio] = '["sample.ogg"]'

          message = message_builder

          expect(message.attachments.first.meta).to include('is_recorded_audio' => true)
        end

        # Parity, not a new decision: the multipart path already applies one entry to every
        # attachment of the same name, with no error and no warning. Inventing a tie-break on one
        # side only is what would be wrong.
        it 'applies one entry to every attachment of that name, exactly as multipart does' do
          params[:attachments] = [
            get_blob_for('spec/assets/avatar.png', 'image/png').signed_id,
            get_blob_for('spec/assets/avatar.png', 'image/png').signed_id
          ]
          params[:attachments_metadata] = { 'avatar.png' => { description: 'legenda' } }

          message = message_builder

          expect(message.attachments.map(&:meta)).to all(include('description' => 'legenda'))
        end

        # A signed ID that does not resolve already fails at the attach, before any of this runs,
        # and it has to keep failing exactly there. Resolving a name must not add a second way to
        # raise, and must not swallow the first one either.
        it 'keeps failing at the attach for a signed ID that does not resolve' do
          params[:attachments] = ['not-a-signed-id']
          params[:attachments_metadata] = { 'avatar.png' => { description: 'legenda' } }

          expect { message_builder }.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
        end

        # The third shape: a macro and an automation rule pass blobs, which answer `filename` and
        # not `original_filename`. No caller sends one together with per-attachment metadata today,
        # so this is consistency, and what it removes is a raise that was waiting for the first one
        # that did.
        it 'reads the name of a blob attachment too' do
          blob = get_blob_for('spec/assets/sample.ogg', 'audio/ogg')
          params[:attachments] = ActiveStorage::Blob.where(id: blob.id)
          params[:is_recorded_audio] = ['sample.ogg']
          params[:attachments_metadata] = { 'sample.ogg' => { description: 'legenda' } }

          message = message_builder

          expect(message.attachments.first.meta)
            .to include('description' => 'legenda', 'is_recorded_audio' => true)
        end

        # Resolving the name must not pay for a second lookup: the file type already resolves the
        # same signed ID once per attachment.
        it 'resolves each signed ID once, not twice' do
          allow(ActiveStorage::Blob).to receive(:find_signed).and_call_original
          params[:attachments_metadata] = { 'avatar.png' => { description: 'legenda' } }

          message_builder

          expect(ActiveStorage::Blob).to have_received(:find_signed).once
        end
      end
    end

    context 'when is_voice_message is true' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.ogg', 'audio/ogg')],
                                           is_voice_message: true
                                         })
      end

      it 'sets is_voice_message in attachment meta' do
        message = message_builder
        expect(message.attachments.first.meta).to include('is_voice_message' => true)
      end
    end

    # The constructor casts this sibling parameter and always did, but nothing measured it, so
    # the guard that keeps a multipart `is_voice_message=false` from going out as a voice note
    # was free to disappear unnoticed. Same string, same request, one line away from the flags
    # this change casts.
    context 'when is_voice_message arrives as the string false' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.ogg', 'audio/ogg')],
                                           is_voice_message: 'false'
                                         })
      end

      it 'leaves the voice flag off' do
        message = message_builder

        expect(message.attachments.first.meta).not_to include('is_voice_message')
      end
    end

    context 'when the voice message is a private note' do
      let(:params) do
        ActionController::Parameters.new({
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/sample.ogg', 'audio/ogg')],
                                           is_voice_message: true,
                                           private: true
                                         })
      end

      it 'attaches the recording to the note like any other message' do
        message = message_builder

        expect(message).to be_private
        expect(message.attachments.first.file_type).to eq 'audio'
        expect(message.attachments.first.meta).to include('is_voice_message' => true)
      end
    end

    context 'when is_voice_message is not provided' do
      let(:params) do
        ActionController::Parameters.new({
                                           content: 'test',
                                           attachments: [Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')]
                                         })
      end

      it 'does not set is_voice_message in attachment meta' do
        message = message_builder
        expect(message.attachments.first.meta).not_to include('is_voice_message')
      end
    end

    context 'when forwarding a message in a non email inbox' do
      let(:params) do
        ActionController::Parameters.new({ content: 'test', to_emails: 'vendor@example.com',
                                           content_attributes: { forwarded_message_id: message_for_reply.id }.to_json })
      end

      it 'rejects the message' do
        expect { message_builder }.to raise_error 'Forwarded emails need an email inbox'
      end
    end

    context 'when email channel messages' do
      let!(:channel_email) { create(:channel_email, account: account) }
      let(:inbox_member) { create(:inbox_member, inbox: channel_email.inbox) }
      let(:conversation) { create(:conversation, inbox: channel_email.inbox, account: account) }
      let(:params) do
        ActionController::Parameters.new({ cc_emails: 'test_cc_mail@test.com', bcc_emails: 'test_bcc_mail@test.com' })
      end

      it 'creates message with content_attributes for cc and bcc email addresses' do
        message = message_builder

        expect(message.content_attributes[:cc_emails]).to eq [params[:cc_emails]]
        expect(message.content_attributes[:bcc_emails]).to eq [params[:bcc_emails]]
      end

      it 'does not create message with wrong cc and bcc email addresses' do
        params = ActionController::Parameters.new({ cc_emails: 'test.com', bcc_emails: 'test_bcc.com' })
        expect { described_class.new(user, conversation, params).perform }.to raise_error 'Invalid email address'
      end

      it 'strips off whitespace before saving cc_emails and bcc_emails' do
        cc_emails = ' test1@test.com , test2@test.com, test3@test.com'
        bcc_emails = 'test1@test.com,test2@test.com, test3@test.com '
        params = ActionController::Parameters.new({ cc_emails: cc_emails, bcc_emails: bcc_emails })

        message = described_class.new(user, conversation, params).perform

        expect(message.content_attributes[:cc_emails]).to eq ['test1@test.com', 'test2@test.com', 'test3@test.com']
        expect(message.content_attributes[:bcc_emails]).to eq ['test1@test.com', 'test2@test.com', 'test3@test.com']
      end

      it 'saves the subject on the message' do
        params = ActionController::Parameters.new({ content: 'test', subject: 'Refund approved' })

        message = described_class.new(user, conversation, params).perform

        expect(message.content_attributes.dig(:email, :subject)).to eq 'Refund approved'
        expect(message.content_attributes.dig(:email, :html_content, :full)).to be_present
      end

      it 'does not save a blank subject' do
        params = ActionController::Parameters.new({ content: 'test', subject: ' ' })

        message = described_class.new(user, conversation, params).perform

        expect(message.content_attributes[:email]).not_to have_key(:subject)
      end

      it 'does not save the subject on a private note' do
        params = ActionController::Parameters.new({ content: 'test', subject: 'Refund approved', private: true })

        message = described_class.new(user, conversation, params).perform

        expect(message.content_attributes[:email]).to be_nil
      end

      context 'when forwarding a message' do
        let(:forwarded_message) { create(:message, conversation: conversation, account: account, message_type: :incoming) }
        let(:forwarded_attachment) do
          attachment = forwarded_message.attachments.new(account_id: account.id, file_type: :image)
          attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          attachment.save!
          attachment
        end
        let(:params) do
          ActionController::Parameters.new({
                                             content: 'Forwarding this',
                                             private: 'false',
                                             to_emails: 'vendor@example.com',
                                             email_html_content: '<p>Forwarding this</p><p>Edited body</p>',
                                             content_attributes: { forwarded_message_id: forwarded_message.id }.to_json,
                                             forwarded_attachment_ids: [forwarded_attachment.id]
                                           })
        end

        it 'copies the selected attachments of the forwarded message' do
          message = message_builder

          expect(message.content_attributes[:forwarded_message_id]).to eq forwarded_message.id
          expect(message.content_attributes[:to_emails]).to eq ['vendor@example.com']
          expect(message.attachments.map { |attachment| attachment.file.blob }).to eq [forwarded_attachment.file.blob]
        end

        it 'keeps the edited html when the private flag arrives as a multipart string' do
          message = message_builder

          expect(message.private).to be(false)
          expect(message.content_attributes.dig(:email, :html_content, :reply)).to eq('<p>Forwarding this</p><p>Edited body</p>')
        end

        it 'rejects a private forward' do
          params[:private] = true

          expect { message_builder }.to raise_error 'Forwarded emails cannot be private'
        end

        it 'ignores attachments that do not belong to the forwarded message' do
          other_message = create(:message, conversation: conversation, account: account)
          other_attachment = other_message.attachments.new(account_id: account.id, file_type: :image)
          other_attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          other_attachment.save!
          params[:forwarded_attachment_ids] = [other_attachment.id]

          expect(message_builder.attachments).to be_empty
        end

        it 'raises when the forwarded message belongs to another conversation' do
          params[:content_attributes] = { forwarded_message_id: create(:message, account: account).id }.to_json

          expect { message_builder }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'raises when no recipient is given' do
          params[:to_emails] = ''

          expect { message_builder }.to raise_error(StandardError, 'Forwarded emails need a recipient')
        end
      end

      context 'when custom email content is provided' do
        it 'creates message with custom HTML email content' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular message content',
                                                      email_html_content: '<p>Custom <strong>HTML</strong> content</p>'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to eq '<p>Custom <strong>HTML</strong> content</p>'
          expect(message.content_attributes.dig('email', 'html_content', 'reply')).to eq '<p>Custom <strong>HTML</strong> content</p>'
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Regular message content'
          expect(message.content_attributes.dig('email', 'text_content', 'reply')).to eq 'Regular message content'
        end

        it 'does not process custom email content for private messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular message content',
                                                      email_html_content: '<p>Custom HTML content</p>',
                                                      private: true
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content')).to be_nil
          expect(message.content_attributes.dig('email', 'text_content')).to be_nil
        end

        it 'falls back to default behavior when no custom email content is provided' do
          params = ActionController::Parameters.new({
                                                      content: 'Regular **markdown** content'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('<strong>markdown</strong>')
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Regular **markdown** content'
        end
      end

      context 'when liquid templates are present in email content' do
        let(:contact) { create(:contact, name: 'John', email: 'john@example.com') }
        let(:conversation) { create(:conversation, inbox: channel_email.inbox, account: account, contact: contact) }

        it 'processes liquid variables in email content' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}, your email is {{contact.email}}'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('Hello John')
          expect(message.content_attributes.dig('email', 'html_content', 'full')).to include('john@example.com')
          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello John, your email is john@example.com'
        end

        it 'does not process liquid in code blocks' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}, use this code: `{{contact.email}}`'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello John, use this code: `{{contact.email}}`'
        end

        it 'handles broken liquid syntax gracefully' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}  {{invalid}}'
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'text_content', 'full')).to eq 'Hello {{contact.name}  {{invalid}}'
        end

        it 'does not process liquid for incoming messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}',
                                                      message_type: 'incoming'
                                                    })

          api_channel = create(:channel_api, account: account)
          api_conversation = create(:conversation, inbox: api_channel.inbox, account: account, contact: contact)

          message = described_class.new(user, api_conversation, params).perform

          expect(message.content).to eq 'Hello {{contact.name}}'
        end

        it 'does not process liquid for private messages' do
          params = ActionController::Parameters.new({
                                                      content: 'Hello {{contact.name}}',
                                                      private: true
                                                    })

          message = described_class.new(user, conversation, params).perform

          expect(message.content_attributes.dig('email', 'html_content')).to be_nil
          expect(message.content_attributes.dig('email', 'text_content')).to be_nil
        end
      end
    end
  end

  describe 'scheduled_message metadata' do
    let(:scheduled_message) { create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: user, content: 'Hello') }
    let(:params) do
      ActionController::Parameters.new({
                                         content: 'test',
                                         scheduled_message: scheduled_message
                                       })
    end

    it 'includes scheduled_message_id in additional_attributes' do
      message = message_builder

      expect(message.additional_attributes['scheduled_message_id']).to eq(scheduled_message.id)
    end

    it 'includes scheduled_by with author info' do
      message = message_builder

      expect(message.additional_attributes['scheduled_by']).to include('id' => user.id, 'type' => 'User', 'name' => user.name)
    end

    it 'includes scheduled_at timestamp' do
      message = message_builder

      expect(message.additional_attributes['scheduled_at']).to eq(scheduled_message.updated_at.to_i)
    end

    context 'when author is AutomationRule' do
      let(:automation_rule) { create(:automation_rule, account: account) }
      let(:scheduled_message) do
        create(:scheduled_message, account: account, inbox: inbox, conversation: conversation, author: automation_rule, content: 'Hello')
      end

      it 'includes scheduled_by with automation_rule info' do
        message = message_builder

        expect(message.additional_attributes['scheduled_by']).to include('id' => automation_rule.id, 'type' => 'AutomationRule')
      end
    end
  end
end
