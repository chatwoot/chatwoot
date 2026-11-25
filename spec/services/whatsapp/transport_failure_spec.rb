require 'rails_helper'

# A send that never gets an answer at all: the socket timed out, the connection was reset, the
# handshake failed. Until fazer-ai/chatwoot#605 those escaped as whatever the HTTP stack raised,
# matched no `retry_on` in SendReplyJob, and Sidekiq re-sent the message three more times with the
# bubble still reading "sent" -- up to four copies in front of the customer and nothing on the
# agent's screen. Measured here through the real send service, because the value is in the whole
# chain and not in the classifier alone.
describe 'a send that gets no answer at all' do # rubocop:disable RSpec/DescribeClass
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, phone_number: '+5511999999999') }
  let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, contact: contact, source_id: '5511999999999') }
  let(:conversation) { create(:conversation, contact_inbox: contact_inbox, contact: contact, inbox: channel.inbox, account: account) }
  let(:message) { create(:message, message_type: :outgoing, content: 'oi', conversation: conversation, account: account) }

  # The window a session message needs: without one the service answers "outside the messaging
  # window" and never reaches a provider at all, which would make every example below pass for
  # the wrong reason.
  before { create(:message, message_type: :incoming, conversation: conversation, account: account) }

  # Not a class: the value is the whole chain, from the provider raising to the bubble the agent
  # reads, and no single class owns that.
  #
  # The three providers that lacked the classification. Baileys is not here: it has had it since
  # #391 and its own spec covers it, and the point of this one is the three that did not.
  {
    'whatsapp_cloud' => :post,
    'zapi' => :post,
    'default' => :post
  }.each do |provider, verb|
    context "when the provider is #{provider}" do
      let(:channel) do
        create(:channel_whatsapp, provider: provider, account: account,
                                  validate_provider_config: false, sync_templates: false)
      end

      # Never transmitted: the connection was refused, so nothing can have reached WhatsApp. The
      # message stays sendable and the error is retryable, which is what lets SendReplyJob try
      # again rather than telling the agent a send failed that never left.
      it 'keeps a refused connection retryable, because nothing can have arrived' do
        allow(HTTParty).to receive(verb).and_raise(Errno::ECONNREFUSED)

        expect { described_class_for(message).perform }
          .to raise_error(Whatsapp::Session::Errors::ProviderUnavailable) { |error| expect(error).to be_retryable }
      end

      # The other half, and the one the issue is about. A read timeout may or may not have been
      # delivered, so re-sending is how the customer gets a second copy. The message is marked
      # failed instead, which both ends the silence and stops the retry.
      it 'marks the message failed on an answer that never came, instead of sending it again' do
        allow(HTTParty).to receive(verb).and_raise(Net::ReadTimeout)

        expect { described_class_for(message).perform }.not_to raise_error

        expect(message.reload.status).to eq('failed')
        expect(message.external_error).to eq(I18n.t('errors.inboxes.channel.outgoing.send_outcome_unknown'))
      end

      it 'does not record a source id for a send it could not confirm' do
        allow(HTTParty).to receive(verb).and_raise(Net::ReadTimeout)

        described_class_for(message).perform

        expect(message.reload.source_id).to be_nil
      end
    end
  end

  def described_class_for(message)
    Whatsapp::SendOnWhatsappService.new(message: message)
  end
end
