require 'rails_helper'

describe Whatsapp::SendOnWhatsappService do
  template_params = {
    name: 'sample_shipping_confirmation',
    namespace: '23423423_2342423_324234234_2343224',
    language: 'en_US',
    category: 'Marketing',
    processed_params: { 'body' => { '1' => '3' } }
  }

  describe '#perform' do
    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      stub_request(:post, 'https://waba.360dialog.io/v1/messages')
    end

    context 'when a valid message' do
      let(:whatsapp_request) { instance_double(HTTParty::Response) }
      let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false) }

      let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }
      let(:api_key) { 'test_key' }
      let(:headers) { { 'D360-API-KEY' => api_key, 'Content-Type' => 'application/json' } }
      let(:template_body) do
        {
          to: '123456789',
          template: {
            name: 'sample_shipping_confirmation',
            namespace: '23423423_2342423_324234234_2343224',
            language: { 'policy': 'deterministic', 'code': 'en_US' },
            components: [{ 'type': 'body', 'parameters': [{ 'type': 'text', 'text': '3' }] }]
          },
          type: 'template'
        }
      end

      let(:named_template_body) do
        {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: '123456789',
          type: 'template',
          template: {
            name: 'ticket_status_updated',
            language: { 'policy': 'deterministic', 'code': 'en_US' },
            components: [{ 'type': 'body',
                           'parameters': [{ 'type': 'text', parameter_name: 'last_name', 'text': 'Dale' },
                                          { 'type': 'text', parameter_name: 'ticket_id', 'text': '2332' }] }]
          }
        }
      end

      let(:success_response) { { 'messages' => [{ 'id' => '123456789' }] }.to_json }

      it 'calls channel.send_message when with in 24 hour limit' do
        # to handle the case of 24 hour window limit.
        create(:message, message_type: :incoming, content: 'test',
                         conversation: conversation, account: conversation.account)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, account: conversation.account)

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: { 'to' => '123456789', 'text' => { 'body' => 'test' }, 'type' => 'text' }.to_json
          )
          .to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'keeps a private note off the channel, attachment and all' do
        create(:message, message_type: :incoming, content: 'test',
                         conversation: conversation, account: conversation.account)
        message = create(:message, message_type: :outgoing, private: true, content: 'heads up',
                                   conversation: conversation, account: conversation.account)
        message.attachments.create!(
          account_id: message.account_id,
          file_type: :audio,
          file: fixture_file_upload('public/audio/widget/ding.mp3')
        )

        described_class.new(message: message).perform

        expect(a_request(:post, 'https://waba.360dialog.io/v1/messages')).not_to have_been_made
      end

      it 'fails a free-form message without contacting the provider when outside the 24 hour limit' do
        create(:message, message_type: :incoming, content: 'test', created_at: 25.hours.ago,
                         conversation: conversation, account: conversation.account)
        message = create(:message, message_type: :outgoing, content: 'test',
                                   conversation: conversation, account: conversation.account)

        expect(Whatsapp::TemplateProcessorService).not_to receive(:new)

        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq(I18n.t('errors.whatsapp.message_outside_messaging_window'))
        expect(a_request(:post, 'https://waba.360dialog.io/v1/messages')).not_to have_been_made
      end

      it 'marks message as failed when template name is blank' do
        processor = instance_double(Whatsapp::TemplateProcessorService)
        allow(Whatsapp::TemplateProcessorService).to receive(:new).and_return(processor)
        allow(processor).to receive(:call).and_return([nil, nil, nil, nil])

        invalid_template_params = {
          name: '',
          namespace: 'test_namespace',
          language: 'en_US',
          category: 'UTILITY',
          processed_params: { '1' => 'test' }
        }

        message = create(:message,
                         additional_attributes: { template_params: invalid_template_params },
                         conversation: conversation,
                         message_type: :outgoing,
                         account: conversation.account)

        described_class.new(message: message).perform

        expect(message.reload.status).to eq('failed')
        expect(message.reload.external_error).to eq('Template not found or invalid template name')
      end

      it 'calls channel.send_template when after 24 hour limit' do
        message = create(:message, message_type: :outgoing, content: 'Your package has been shipped. It will be delivered in 3 business days.',
                                   conversation: conversation, additional_attributes: { template_params: template_params },
                                   account: conversation.account)

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template if template_params are present' do
        message = create(:message, additional_attributes: { template_params: template_params },
                                   content: 'Your package will be delivered in 3 business days.', conversation: conversation, message_type: :outgoing,
                                   account: conversation.account)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template with named params if template parameter type is NAMED' do
        whatsapp_cloud_channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
        cloud_contact_inbox = create(:contact_inbox, inbox: whatsapp_cloud_channel.inbox, source_id: '123456789')
        cloud_conversation = create(:conversation, contact_inbox: cloud_contact_inbox, inbox: whatsapp_cloud_channel.inbox)

        named_template_params = {
          name: 'ticket_status_updated',
          language: 'en_US',
          category: 'UTILITY',
          processed_params: { 'body' => { 'last_name' => 'Dale', 'ticket_id' => '2332' } }
        }

        stub_request(:post, "https://graph.facebook.com/v13.0/#{whatsapp_cloud_channel.provider_config['phone_number_id']}/messages")
          .with(
            :headers => {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{whatsapp_cloud_channel.provider_config['api_key']}",
              'User-Agent' => 'Ruby'
            },
            :body => named_template_body.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
        message = create(:message,
                         additional_attributes: { template_params: named_template_params },
                         content: 'Your package will be delivered in 3 business days.', conversation: cloud_conversation, message_type: :outgoing,
                         account: cloud_conversation.account)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'calls channel.send_template when template has regexp characters' do
        regexp_template_params = build_template_params('customer_yes_no', '2342384942_32423423_23423fdsdaf23', 'ar', {})
        arabic_content = 'عميلنا العزيز الرجاء الرد على هذه الرسالة بكلمة *نعم* للرد على إستفساركم من قبل خدمة العملاء.'
        message = create_message_with_template(arabic_content, regexp_template_params)
        stub_template_request(regexp_template_params, [])

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles template with header parameters' do
        processed_params = {
          'body' => { '1' => '3' },
          'header' => { 'media_url' => 'https://example.com/image.jpg', 'media_type' => 'image' }
        }
        header_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', header_template_params)

        components = [
          { type: 'header', parameters: [{ type: 'image', image: { link: 'https://example.com/image.jpg' } }] },
          { type: 'body', parameters: [{ type: 'text', text: '3' }] }
        ]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles empty processed_params gracefully' do
        empty_template_params = {
          name: 'sample_shipping_confirmation',
          namespace: '23423423_2342423_324234234_2343224',
          language: 'en_US',
          category: 'SHIPPING_UPDATE',
          processed_params: {}
        }

        message = create(:message, additional_attributes: { template_params: empty_template_params },
                                   conversation: conversation, message_type: :outgoing, account: conversation.account)

        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: 'sample_shipping_confirmation',
                namespace: '23423423_2342423_324234234_2343224',
                language: { 'policy': 'deterministic', 'code': 'en_US' },
                components: []
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles template with button parameters' do
        processed_params = {
          'body' => { '1' => '3' },
          'buttons' => [{ 'type' => 'url', 'parameter' => 'https://track.example.com/123' }]
        }
        button_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', button_template_params)

        components = [
          { type: 'body', parameters: [{ type: 'text', text: '3' }] },
          { type: 'button', sub_type: 'url', index: 0, parameters: [{ type: 'text', text: 'https://track.example.com/123' }] }
        ]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'processes template parameters correctly via integration' do
        processed_params = {
          'body' => { '1' => '5' },
          'footer' => { 'text' => 'Thank you' }
        }
        complex_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', complex_template_params)

        components = [
          { type: 'body', parameters: [{ type: 'text', text: '5' }] },
          { type: 'footer', parameters: [{ type: 'text', text: 'Thank you' }] }
        ]
        stub_sample_template_request(components)

        expect { described_class.new(message: message).perform }.not_to raise_error
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles edge case with missing template gracefully' do
        # Test the service behavior when template is not found
        missing_template_params = {
          'name' => 'non_existent_template',
          'namespace' => 'missing_namespace',
          'language' => 'en_US',
          'category' => 'UTILITY',
          'processed_params' => { 'body' => { '1' => 'test' } }
        }

        service = Whatsapp::TemplateProcessorService.new(
          channel: whatsapp_channel,
          template_params: missing_template_params
        )

        expect { service.call }.not_to raise_error
        name, namespace, language, processed_params = service.call
        expect(name).to eq('non_existent_template')
        expect(namespace).to eq('missing_namespace')
        expect(language).to eq('en_US')
        expect(processed_params).to be_nil
      end

      it 'handles template with blank parameter values correctly' do
        processed_params = {
          'body' => { '1' => '', '2' => 'valid_value', '3' => nil },
          'header' => { 'media_url' => '', 'media_type' => 'image' }
        }
        blank_values_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', blank_values_template_params)

        components = [{ type: 'body', parameters: [{ type: 'text', text: 'valid_value' }] }]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      it 'handles nil template_params gracefully' do
        # Test service behavior when template_params is completely nil
        message = create(:message, additional_attributes: {},
                                   conversation: conversation, message_type: :outgoing)

        # Should send regular message, not template
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              text: { body: message.content },
              type: 'text'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })

        expect { described_class.new(message: message).perform }.not_to raise_error
      end

      it 'fails the message with the reason when a media parameter is rejected' do
        processed_params = {
          'body' => { '1' => '3' },
          'header' => { 'media_url' => 'ftp://example.com/image.jpg', 'media_type' => 'image' }
        }
        rejected_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', rejected_template_params)

        expect { described_class.new(message: message).perform }.not_to raise_error
        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq('Invalid URL scheme: ftp. Only http and https are allowed')
      end

      it 'processes template with rich text formatting' do
        processed_params = { 'body' => { '1' => '*Bold text* and _italic text_' } }
        rich_text_template_params = build_sample_template_params(processed_params)
        message = create_message_with_template('', rich_text_template_params)

        components = [{ type: 'body', parameters: [{ type: 'text', text: '*Bold text* and _italic text_' }] }]
        stub_sample_template_request(components)

        described_class.new(message: message).perform
        expect(message.reload.source_id).to eq('123456789')
      end

      private

      def build_template_params(name, namespace, language, processed_params)
        {
          name: name,
          namespace: namespace,
          language: language,
          category: 'SHIPPING_UPDATE',
          processed_params: processed_params
        }
      end

      def create_message_with_template(content, template_params)
        create(:message,
               message_type: :outgoing,
               content: content,
               conversation: conversation,
               additional_attributes: { template_params: template_params })
      end

      def stub_template_request(template_params, components)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: template_params[:name],
                namespace: template_params[:namespace],
                language: { 'policy': 'deterministic', 'code': template_params[:language] },
                components: components
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
      end

      def build_sample_template_params(processed_params)
        build_template_params('sample_shipping_confirmation', '23423423_2342423_324234234_2343224', 'en_US', processed_params)
      end

      def stub_sample_template_request(components)
        stub_request(:post, 'https://waba.360dialog.io/v1/messages')
          .with(
            headers: headers,
            body: {
              to: '123456789',
              template: {
                name: 'sample_shipping_confirmation',
                namespace: '23423423_2342423_324234234_2343224',
                language: { 'policy': 'deterministic', 'code': 'en_US' },
                components: components
              },
              type: 'template'
            }.to_json
          ).to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
      end
    end

    context 'when provider is baileys' do
      let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: true) }
      let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }

      before do
        stub_request(:get, 'https://baileys.api/status/auth')
          .with(
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Content-Type' => 'application/json',
              'User-Agent' => 'Ruby',
              'X-Api-Key' => 'test_key'
            }
          )
          .to_return(status: 200, body: '', headers: {})
      end

      it 'uses phone number as recipient_id for individual contacts' do
        conversation.contact.update!(phone_number: '+123456789')
        message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

        allow(whatsapp_channel).to receive(:send_message).with('123456789', message).and_return('123456789')

        described_class.new(message: message).perform

        expect(message.reload.source_id).to eq('123456789')
      end

      it 'falls back to identifier when contact has no phone_number' do
        conversation.contact.update!(phone_number: nil, identifier: '99999999@lid')
        message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

        allow(whatsapp_channel).to receive(:send_message).with('99999999@lid', message).and_return('msg_lid')

        described_class.new(message: message).perform

        expect(message.reload.source_id).to eq('msg_lid')
      end

      it 'uses identifier as recipient_id for group contacts' do
        conversation.contact.update!(identifier: '123456789123456789@g.us', group_type: :group)
        message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

        allow(whatsapp_channel).to receive(:send_message).with('123456789123456789@g.us', message).and_return('msg_group')

        described_class.new(message: message).perform

        expect(message.reload.source_id).to eq('msg_group')
      end

      # The bubble used to sit on "sent" with a clock next to it while Sidekiq retried a
      # send that could never work, and then died in the dead set with nobody watching.
      # The agent had no way to know it had not gone out.
      describe 'a send the provider will refuse again' do
        let(:message) { create(:message, message_type: :outgoing, content: 'test', conversation: conversation) }

        it 'fails the message with the reason instead of raising' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Session::Errors::MediaTooLarge, 'The attachment is too large to send'
          )

          expect { described_class.new(message: message).perform }.not_to raise_error

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('The attachment is too large to send')
        end

        it 'fails the message when the send outcome cannot be determined' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Providers::WhatsappBaileysService::SendOutcomeUnknownError, 'may have gone through'
          )

          expect { described_class.new(message: message).perform }.not_to raise_error

          expect(message.reload.status).to eq('failed')
          expect(message.external_error).to eq('may have gone through')
        end

        # retryable? is false for a processing conflict, but the message is NOT failed:
        # another worker holds the idempotency lock and is sending it right now. Failing
        # it here would both lie to the agent and swallow the dedicated backoff
        # SendReplyJob has for exactly this conflict, which never runs if the exception
        # does not reach the job.
        it 'lets a processing conflict reach the job instead of failing the message' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Providers::WhatsappBaileysService::MessageAlreadyProcessingError
          )

          expect { described_class.new(message: message).perform }.to raise_error(
            Whatsapp::Session::Errors::MessageAlreadyProcessing
          )

          expect(message.reload.status).not_to eq('failed')
        end

        # A send that timed out may still have reached WhatsApp, so a receipt can mark
        # this message delivered while we are deciding it failed. Walking that back is
        # what puts a duplicate in front of the customer.
        it 'leaves a message the provider already confirmed delivered alone' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Providers::WhatsappBaileysService::SendOutcomeUnknownError, 'may have gone through'
          )
          delivered = create(
            :message,
            message_type: :outgoing,
            content: 'test',
            conversation: conversation,
            status: :delivered
          )

          described_class.new(message: delivered).perform

          expect(delivered.reload.status).to eq('delivered')
          expect(delivered.external_error).to be_blank
        end

        # The other half: a provider that is down answers differently once it is back, so
        # the job has to fail and be retried rather than bury a message the agent could
        # still send.
        it 'lets a retryable error take the job down with it' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Session::Errors::ProviderUnavailable
          )

          expect { described_class.new(message: message).perform }.to raise_error(
            Whatsapp::Session::Errors::ProviderUnavailable
          )

          expect(message.reload.status).not_to eq('failed')
        end

        # validate_announcement_mode! writes its own translated sentence before raising;
        # the exception's message is the English one meant for the log.
        it 'does not overwrite a reason already recorded on the message' do
          allow(whatsapp_channel).to receive(:send_message).and_raise(
            Whatsapp::Session::Errors::MediaTooLarge, 'the later reason'
          )
          failed_message = create(
            :message,
            message_type: :outgoing,
            content: 'test',
            conversation: conversation,
            status: :failed,
            content_attributes: { external_error: 'already recorded' }
          )

          described_class.new(message: failed_message).perform

          expect(failed_message.reload.external_error).to eq('already recorded')
        end
      end

      describe 'a read timeout on the send' do
        let(:send_message_url) do
          "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/send-message"
        end
        let(:setup_url) do
          "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}"
        end
        let(:success_body) { { data: { key: { id: 'wa_msg_123' }, messageTimestamp: '123' } }.to_json }

        before do
          conversation.contact.update!(phone_number: '+123456789')
          create(:message, message_type: :incoming, content: 'hi', conversation: conversation)
          stub_request(:post, setup_url).to_return(status: 200, body: '', headers: {})
        end

        # A transport failure used to escape as Net::ReadTimeout, which is not in the session
        # hierarchy, so SendReplyJob's retry_on never saw it: Sidekiq burned its native
        # retries and the job died in the dead set with the bubble still reading 'sent'.
        # That is the silent failure this whole change exists to remove, so the transport is
        # translated too. A read timeout says the same thing a 504 does — the send may or may
        # not have arrived — which is why it maps to the retryable timeout and not to a
        # provider-down error.
        it 'translates into the session hierarchy so the job can retry it' do
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation, source_id: nil)

          stub_request(:post, send_message_url)
            .with { |req| JSON.parse(req.body)['chatwootMessageId'].to_s.start_with?("#{message.id}:") }
            .to_raise(Net::ReadTimeout.new('Net::ReadTimeout'))

          expect { described_class.new(message: message).perform }.to(raise_error do |e|
            expect(e.class.name).to eq('Whatsapp::Providers::WhatsappBaileysService::SendTimeoutError')
            expect(e.retryable?).to be(true)
          end)

          # Not failed: the send may still have arrived, and the retry reuses the reserved id
          # so WhatsApp dedupes it rather than delivering twice.
          expect(message.reload.status).not_to eq('failed')
          expect(message.pending_source_id).to be_present
        end

        # An enumerated list of exception types is a promise to have thought of every way a
        # socket can fail, and it will be wrong: Net::WriteTimeout on a large media body,
        # OpenSSL::SSL::SSLError on a handshake, whatever the next gem raises. Rescued as a
        # class instead, which is why nothing but the HTTP call is inside that rescue.
        [
          [Net::WriteTimeout, 'Whatsapp::Providers::WhatsappBaileysService::SendTimeoutError'],
          [OpenSSL::SSL::SSLError, 'Whatsapp::Providers::WhatsappBaileysService::SendTimeoutError'],
          [Net::OpenTimeout, 'Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError'],
          [SocketError, 'Whatsapp::Providers::WhatsappBaileysService::ProviderUnavailableError']
        ].each do |raised, expected|
          it "maps #{raised} into the session hierarchy" do
            message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation, source_id: nil)
            stub_request(:post, send_message_url).to_raise(raised)

            expect { described_class.new(message: message).perform }.to(raise_error do |e|
              expect(e.class.name).to eq(expected)
              expect(e.retryable?).to be(true)
            end)
          end
        end

        # A send that may already be on the wire must not mark the channel closed: that
        # drops the inbox out of the health-check cycle. A connect that never left our
        # socket is a real provider-down signal and should.
        it 'leaves the channel open for a write that may already have been transmitted' do
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation, source_id: nil)
          stub_request(:post, send_message_url).to_raise(Net::WriteTimeout)

          expect { described_class.new(message: message).perform }.to raise_error(Whatsapp::Session::Errors::Timeout)

          expect(WebMock).not_to have_requested(:post, setup_url)
        end

        # The retry sends the same reserved WhatsApp id, which is what makes it safe: two
        # requests, one message on the customer's phone.
        it 'reuses the reserved id when the retry goes through' do
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation, source_id: nil)
          sent_ids = []

          stub = stub_request(:post, send_message_url)
                 .with { |req| sent_ids << JSON.parse(req.body)['messageId'] }
                 .to_raise(Net::ReadTimeout.new('Net::ReadTimeout'))
                 .then
                 .to_return(status: 200, body: success_body, headers: { 'Content-Type' => 'application/json' })

          expect { described_class.new(message: message).perform }.to raise_error(Whatsapp::Session::Errors::Timeout)
          described_class.new(message: message).perform

          expect(stub).to have_been_requested.twice
          expect(sent_ids.uniq.length).to eq(1)
          expect(message.reload.source_id).to eq('wa_msg_123')
        end
      end
    end

    context 'when provider is zapi' do
      let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'zapi', validate_provider_config: false) }
      let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
      let(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }
      let(:success_response) { { 'messageId' => 'msg_123' }.to_json }

      before do
        stub_request(:post, /.*/)
          .to_return(status: 200, body: success_response, headers: { 'content-type' => 'application/json' })
      end

      context 'with recipient_id logic' do
        it 'uses phone number when contact has phone_number for session messages' do
          conversation.contact.update!(phone_number: '+5511987654321')
          create(:message, message_type: :incoming, content: 'test', conversation: conversation)
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

          expect(whatsapp_channel).to receive(:send_message).with('5511987654321', message).and_return('msg_123')

          described_class.new(message: message).perform
        end

        it 'uses identifier with @lid suffix when contact has no phone_number for session messages' do
          conversation.contact.update!(phone_number: nil, identifier: '123456789@lid')
          create(:message, message_type: :incoming, content: 'test', conversation: conversation)
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

          expect(whatsapp_channel).to receive(:send_message).with('123456789@lid', message).and_return('msg_123')

          described_class.new(message: message).perform
        end

        it 'uses identifier as recipient_id for group contacts' do
          conversation.contact.update!(identifier: '120363123456789@g.us', group_type: :group)
          create(:message, message_type: :incoming, content: 'test', conversation: conversation)
          message = create(:message, message_type: :outgoing, content: 'test', conversation: conversation)

          expect(whatsapp_channel).to receive(:send_message).with('120363123456789@g.us', message).and_return('msg_group')

          described_class.new(message: message).perform
        end
      end
    end

    context 'when a contact information template becomes ineligible before delivery' do
      let(:request_template) do
        {
          'name' => 'request_contact_info',
          'status' => 'APPROVED',
          'language' => 'en_US',
          'components' => [
            { 'type' => 'BODY', 'text' => 'Would you like to share your phone number with us?' },
            { 'type' => 'BUTTONS', 'buttons' => [{ 'type' => 'REQUEST_CONTACT_INFO' }] }
          ]
        }
      end
      let(:whatsapp_channel) do
        create(
          :channel_whatsapp,
          provider: 'whatsapp_cloud',
          message_templates: [request_template],
          sync_templates: false,
          validate_provider_config: false
        )
      end
      let(:inbox) { whatsapp_channel.inbox }
      let(:contact) { create(:contact, account: inbox.account, phone_number: nil) }
      let(:contact_inbox) do
        create(:contact_inbox, inbox: inbox, contact: contact, source_id: 'AE.2109889333218546')
      end
      let(:conversation) do
        create(:conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox)
      end

      it 'marks the message failed when another request is already pending' do
        previous_conversation = create(
          :conversation, account: inbox.account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :resolved
        )
        create(
          :message,
          account: inbox.account,
          inbox: inbox,
          conversation: previous_conversation,
          message_type: :outgoing,
          status: :sent,
          content_attributes: { whatsapp_contact_info: { type: 'request', state: 'pending' } }
        )
        message = create(
          :message,
          account: inbox.account,
          inbox: inbox,
          conversation: conversation,
          message_type: :outgoing,
          additional_attributes: {
            template_params: {
              name: request_template['name'],
              language: request_template['language'],
              processed_params: {}
            }
          }
        )
        expect(Whatsapp::TemplateProcessorService).not_to receive(:new)

        expect { described_class.new(message: message).perform }.not_to raise_error

        expect(message.reload).to have_attributes(
          status: 'failed',
          external_error: I18n.t('errors.whatsapp.contact_info_request.pending_request')
        )
      end
    end

    context 'when a merged contact owns multiple Meta Cloud identities' do
      let!(:whatsapp_channel) do
        create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      end
      let(:account) { whatsapp_channel.inbox.account }
      let!(:contact_a) { create(:contact, account: account, name: 'Customer A') }
      let!(:contact_b) { create(:contact, account: account, name: 'Customer B') }
      let!(:contact_inbox_a) do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact_a, source_id: 'AE.QACUSTOMERA')
      end
      let!(:contact_inbox_b) do
        create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact_b, source_id: 'AE.QACUSTOMERB')
      end
      let!(:conversation_a) do
        create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: contact_a, contact_inbox: contact_inbox_a)
      end
      let!(:conversation_b) do
        create(:conversation, account: account, inbox: whatsapp_channel.inbox, contact: contact_b, contact_inbox: contact_inbox_b)
      end

      it 'sends each reply to the source id of its exact conversation contact inbox' do
        ContactMergeAction.new(account: account, base_contact: contact_a, mergee_contact: contact_b).perform
        conversation_a.reload
        conversation_b.reload
        create(:message, account: account, conversation: conversation_a, message_type: :incoming, content: 'incoming A')
        create(:message, account: account, conversation: conversation_b, message_type: :incoming, content: 'incoming B')
        message_a = create(:message, account: account, conversation: conversation_a, message_type: :outgoing, content: 'reply A')
        message_b = create(:message, account: account, conversation: conversation_b, message_type: :outgoing, content: 'reply B')
        channel_a = message_a.conversation.inbox.channel
        channel_b = message_b.conversation.inbox.channel

        expect(channel_a).to receive(:send_message).with('AE.QACUSTOMERA', message_a).and_return('provider-id-a')
        expect(channel_b).to receive(:send_message).with('AE.QACUSTOMERB', message_b).and_return('provider-id-b')

        described_class.new(message: message_a).perform
        described_class.new(message: message_b).perform
      end
    end
  end
end
