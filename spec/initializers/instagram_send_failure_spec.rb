require 'rails_helper'

# The guard lives in config/initializers/instagram_send_failure.rb and is prepended at boot, so
# there is no class of ours to name here. What is worth covering is the one thing that decides
# whether an agent ever learns the send did not happen: what the message row says afterwards.
describe 'InstagramSendFailure' do
  let(:account) { create(:account, locale: 'pt_BR') }
  let(:agent) { create(:user, account: account) }
  let!(:channel) { create(:channel_instagram, account: account) }
  let(:inbox) { channel.inbox }
  let!(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox, account: account) }
  let(:message) do
    create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account, sender: agent)
  end
  let(:service) { Instagram::SendOnInstagramService.new(message: message) }

  # Método e não `let`: é a leitura de uma chave fixa, sem nada a memoizar.
  def reason
    I18n.with_locale(:pt_BR) { I18n.t('errors.meta.send_failed') }
  end

  describe 'an unexpected error before anything left' do
    before { allow(HTTParty).to receive(:post).and_raise(RuntimeError, 'boom na chamada') }

    it 'leaves the message failed with a sentence instead of leaving it looking sent' do
      service.perform

      expect(message.reload).to have_attributes(status: 'failed', external_error: reason, source_id: nil)
    end

    it 'says nothing about the exception itself, which is for the tracker and not for the agent' do
      service.perform

      expect(message.reload.external_error).not_to include('RuntimeError', 'boom na chamada', 'instagram/base_send_service')
    end

    it 'still reports to the tracker, and still does not let the error escape to the job' do
      tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
      captured = []
      allow(ChatwootExceptionTracker).to receive(:new) do |error, **_options|
        captured << error
        tracker
      end

      expect { service.perform }.not_to raise_error
      expect(captured.map { |e| [e.class, e.message] }).to eq([[RuntimeError, 'boom na chamada']])
    end

    it 'writes the sentence in the language of the account that owns the message' do
      written = %w[pt_BR en es].map do |locale|
        account.update!(locale: locale)
        message.update!(status: :sent, content_attributes: {})
        service.perform
        message.reload.external_error
      end

      expect(written).to all(be_present)
      expect(written.uniq.size).to eq(3)
      expect(written.join).not_to include('translation missing', 'errors.meta')
    end
  end

  # The reported defect, and the reason this is worth fixing at all: nothing raises out of the
  # service, so no job fails, nothing retries, and the only trace is an entry in a tracker.
  describe 'a missing app secret on the Instagram-over-page service' do
    let!(:page_channel) { create(:channel_instagram_fb_page, account: account) }
    let!(:page_inbox) { create(:inbox, channel: page_channel, account: account, greeting_enabled: false) }
    let(:page_contact_inbox) { create(:contact_inbox, contact: contact, inbox: page_inbox) }
    let(:page_conversation) do
      create(:conversation, contact: contact, inbox: page_inbox, contact_inbox: page_contact_inbox, account: account)
    end
    let(:page_message) do
      create(:message, message_type: :outgoing, conversation: page_conversation, inbox: page_inbox, account: account, sender: agent)
    end

    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('FB_APP_SECRET', '').and_return(nil)
      allow(HTTParty).to receive(:post)
    end

    it 'fails the message rather than dropping the reply on the floor' do
      Instagram::Messenger::SendOnInstagramService.new(message: page_message).perform

      expect(HTTParty).not_to have_received(:post)
      expect(page_message.reload).to have_attributes(status: 'failed', external_error: reason, source_id: nil)
    end
  end

  # `perform_reply` offers attachments before content and `process_response` writes source_id on
  # each success, so a message can be half delivered when something raises. Walking that back to
  # failed invites a resend, and the contact gets the first attachment twice.
  describe 'an error after part of the message already left' do
    let(:message) do
      msg = build(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account,
                            sender: agent, content: 'segue em anexo')
      2.times do |i|
        attachment = msg.attachments.new(account_id: account.id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: "a#{i}.png", content_type: 'image/png')
      end
      msg.save!
      msg
    end

    before do
      delivered = 0
      allow(HTTParty).to receive(:post) do
        delivered += 1
        raise 'boom no segundo anexo' if delivered > 1

        instance_double(HTTParty::Response, :success? => true, :parsed_response => { 'message_id' => 'mid.primeiro' })
      end
    end

    it 'keeps the message on sent, with the id of what did leave' do
      service.perform

      expect(message.reload).to have_attributes(status: 'sent', source_id: 'mid.primeiro', external_error: nil)
      expect(Message.where(id: message.id).count).to eq(1)
    end
  end

  # Meta refusing the send is not an exception: process_response already writes Meta's own text,
  # which names the actual problem and is worth more to the agent than a generic sentence.
  describe 'a refusal Meta itself returned' do
    before do
      allow(HTTParty).to receive(:post).and_return(
        instance_double(HTTParty::Response, :success? => false,
                                            :parsed_response => { 'error' => { 'code' => 551,
                                                                               'message' => "This person isn't available right now." } })
      )
    end

    it 'keeps Meta wording and does not overwrite it with ours' do
      service.perform

      expect(message.reload).to have_attributes(status: 'failed',
                                                external_error: "551 - This person isn't available right now.",
                                                source_id: nil)
      expect(message.external_error).not_to include(reason)
    end
  end

  # Reachable because attachments go out one at a time and a refusal does not raise: Meta can
  # turn the first one down, which writes its reason, and the second can then blow up. Ours is
  # generic and Meta's names the actual problem, so the first reason written wins.
  describe 'an error raised after Meta already refused something' do
    let(:message) do
      msg = build(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account,
                            sender: agent, content: 'segue em anexo')
      2.times do |i|
        attachment = msg.attachments.new(account_id: account.id, file_type: :image)
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: "b#{i}.png", content_type: 'image/png')
      end
      msg.save!
      msg
    end

    before do
      offered = 0
      allow(HTTParty).to receive(:post) do
        offered += 1
        raise 'boom no segundo anexo' if offered > 1

        instance_double(HTTParty::Response, :success? => false,
                                            :parsed_response => { 'error' => { 'code' => 551,
                                                                               'message' => "This person isn't available right now." } })
      end
    end

    it 'keeps the reason Meta gave instead of replacing it with the generic one' do
      service.perform

      expect(message.reload).to have_attributes(status: 'failed',
                                                external_error: "551 - This person isn't available right now.")
      expect(message.external_error).not_to eq(reason)
    end
  end

  describe 'a send that worked' do
    before do
      allow(HTTParty).to receive(:post).and_return(
        instance_double(HTTParty::Response, :success? => true, :parsed_response => { 'message_id' => 'mid.ok' })
      )
    end

    it 'is left exactly as it was' do
      service.perform

      expect(message.reload).to have_attributes(status: 'sent', source_id: 'mid.ok', external_error: nil)
    end
  end

  describe 'the wiring' do
    it 'sits in front of the base service, which is where both Instagram services rescue' do
      ancestors = Instagram::BaseSendService.ancestors
      expect(ancestors.index(InstagramSendFailure::MarkFailed)).to be < ancestors.index(Instagram::BaseSendService)
      expect(Instagram::BaseSendService.private_method_defined?(:handle_error)).to be(true)
    end
  end
end
