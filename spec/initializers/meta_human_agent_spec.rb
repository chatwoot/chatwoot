require 'rails_helper'

# The guard lives in config/initializers/meta_human_agent.rb and is prepended at boot, so there
# is no class of ours to name here. What is worth covering is which sender carries Meta's
# human-agent seal, and what an agent reads when Meta refuses a send for being out of window.
describe 'MetaHumanAgent' do
  let(:account) { create(:account, locale: 'pt_BR') }
  let(:agent) { create(:user, account: account) }
  let(:agent_bot) { create(:agent_bot, account: account) }
  let(:bodies) { [] }

  # Methods rather than `let`: these are Meta's own payloads, fixed and with nothing to memoize.
  def window_refusal
    { 'error' => { 'message' => 'This message is sent outside of allowed window.',
                   'type' => 'OAuthException', 'code' => 10, 'error_subcode' => 2_018_278 } }
  end

  def token_refusal
    { 'error' => { 'message' => 'Error validating access token: Session has expired',
                   'type' => 'OAuthException', 'code' => 190 } }
  end

  # Both flags at once: an installation that asked Meta for the feature holds a single app, and
  # the two channels are approved and configured together.
  def human_agent_feature(value)
    %w[ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT].each do |name|
      InstallationConfig.where(name: name).first_or_initialize.update!(value: value)
    end
    GlobalConfig.clear_cache
  end

  # `sealed` is the same two keys on every service. What "plain" looks like is not: Messenger
  # names the type and the two Instagram services say nothing at all, which is exactly what each
  # of them already sends when the installation never asked for the feature.
  shared_examples 'a service that seals only what a person wrote' do
    let(:sealed) { { messaging_type: 'MESSAGE_TAG', tag: 'HUMAN_AGENT' } }

    context 'when the installation holds the human agent feature' do
      # The seal is for a reply past the 24-hour window, so the contact last wrote before it.
      before do
        human_agent_feature(true)
        create(:message, message_type: :incoming, conversation: conversation, inbox: inbox, account: account,
                         created_at: 25.hours.ago)
      end

      it 'does not seal an agent reply while the 24-hour window is still open' do
        create(:message, message_type: :incoming, conversation: conversation, inbox: inbox, account: account)
        message.update!(sender: agent)

        service.perform

        expect(bodies.last).not_to include(sealed)
      end

      it 'seals the reply an agent wrote' do
        message.update!(sender: agent)

        service.perform

        expect(bodies.last).to include(sealed)
        expect(bodies.last[:recipient]).to eq(id: contact.get_source_id(inbox.id))
      end

      it 'sends an agent bot reply exactly as it sends with the feature off' do
        message.update!(sender: agent_bot)

        service.perform
        with_feature = bodies.last

        message.update!(source_id: nil)
        human_agent_feature(false)
        service.perform

        expect(with_feature).to eq(bodies.last)
        expect(with_feature).to include(plain_keys) if plain_keys.any?
        absent_keys.each { |key| expect(with_feature).not_to have_key(key) }
      end

      it 'sends a reply nobody signed, as automations and satisfaction surveys create it' do
        message.update!(sender: nil)

        service.perform

        expect(bodies.last).to include(plain_keys) if plain_keys.any?
        absent_keys.each { |key| expect(bodies.last).not_to have_key(key) }
        expect(message.reload).to have_attributes(source_id: 'mid.sent', status: 'sent')
      end

      # Picked by shape rather than by position: Instagram offers the attachment before the text
      # and Messenger after it, and what matters is the attachment body either way.
      it 'follows the same rule in an attachment body' do
        message.attachments.new(account_id: account.id, file_type: :image)
               .file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        message.update!(sender: agent_bot)
        service.perform
        from_a_bot = bodies.find { |body| body[:message].key?(:attachment) }

        bodies.clear
        message.update!(source_id: nil, sender: agent)
        service.perform
        from_a_person = bodies.find { |body| body[:message].key?(:attachment) }

        expect(from_a_bot[:message][:attachment]).to include(type: 'image')
        expect(from_a_bot).to include(plain_keys) if plain_keys.any?
        absent_keys.each { |key| expect(from_a_bot).not_to have_key(key) }
        expect(from_a_person[:message][:attachment]).to include(type: 'image')
        expect(from_a_person).to include(sealed)
      end
    end

    context 'when the installation never asked for the feature' do
      before { human_agent_feature(false) }

      it 'sends the reply an agent wrote the way it always did' do
        message.update!(sender: agent)

        service.perform

        expect(bodies.last).to include(plain_keys) if plain_keys.any?
        absent_keys.each { |key| expect(bodies.last).not_to have_key(key) }
        expect(bodies.last[:message]).to eq(text: message.content)
      end
    end
  end

  # Meta refuses a send past the window with code 10. Upstream persists "10 - (#10) This message
  # is sent outside..." into external_error, which the dashboard shows in the tooltip of a failed
  # bubble: true, unactionable, and in English whatever the account speaks.
  shared_examples 'a service that explains a closed window' do
    before { human_agent_feature(true) }

    it 'tells an automated sender to hand the conversation over, in the account language' do
      message.update!(sender: agent_bot)

      service.perform

      in_portuguese = I18n.with_locale(:pt_BR) { I18n.t('errors.meta.messaging_window_closed_for_automation') }
      expect(message.reload).to have_attributes(status: 'failed', external_error: in_portuguese)
      expect(message.external_error).not_to include('outside of allowed window', '10 - ')
      expect(message.external_error).to include('24')
      expect(channel.reload).not_to be_reauthorization_required
      expect(channel.authorization_error_count).to eq(0)
    end

    it 'tells a person the window reopens when the contact writes, and says it differently' do
      message.update!(sender: agent)

      service.perform
      for_a_person = message.reload.external_error

      expect(message.status).to eq('failed')
      expect(for_a_person).not_to include('outside of allowed window', '10 - ')
      expect(for_a_person).not_to eq(I18n.with_locale(:pt_BR) { I18n.t('errors.meta.messaging_window_closed_for_automation') })
      expect(for_a_person).to eq(I18n.with_locale(:pt_BR) { I18n.t('errors.meta.messaging_window_closed') })
    end

    it 'writes a different sentence for each language the fork ships' do
      message.update!(sender: agent_bot)

      written = %w[pt_BR en es].map do |locale|
        account.update!(locale: locale)
        service.perform
        message.reload.external_error
      end

      expect(written).to all(be_present)
      expect(written.uniq.size).to eq(3)
    end
  end

  describe Instagram::SendOnInstagramService do
    let!(:channel) { create(:channel_instagram, account: account) }
    let(:inbox) { channel.inbox }
    let!(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
    let(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox, account: account) }
    let(:message) { create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account) }
    let(:service) { described_class.new(message: message) }
    let(:plain_keys) { {} }
    let(:absent_keys) { %i[messaging_type tag] }
    let(:transport) { { 'message_id' => 'mid.sent' } }

    before do
      allow(HTTParty).to receive(:post) do |_url, **options|
        bodies << options[:body]
        instance_double(HTTParty::Response, :success? => !transport.key?('error'), :parsed_response => transport)
      end
    end

    it_behaves_like 'a service that seals only what a person wrote'

    context 'when Meta refuses the send for being out of window' do
      let(:transport) { window_refusal }

      it_behaves_like 'a service that explains a closed window'
    end

    it 'leaves every other refusal as upstream writes it, reauthorization included' do
      human_agent_feature(true)
      allow(HTTParty).to receive(:post).and_return(
        instance_double(HTTParty::Response, :success? => false, :parsed_response => token_refusal)
      )
      from_a_person = create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account, sender: agent)
      from_a_bot = create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account, sender: agent_bot)

      [from_a_person, from_a_bot].each { |msg| described_class.new(message: msg).perform }

      raw = '190 - Error validating access token: Session has expired'
      expect(from_a_person.reload).to have_attributes(status: 'failed', external_error: raw)
      expect(from_a_bot.reload).to have_attributes(status: 'failed', external_error: raw)
      expect(channel.reload.authorization_error_count).to eq(2)
      expect(channel).to be_reauthorization_required
    end
  end

  describe Instagram::Messenger::SendOnInstagramService do
    let!(:channel) { create(:channel_instagram_fb_page, account: account) }
    let!(:inbox) { create(:inbox, channel: channel, account: account, greeting_enabled: false) }
    let!(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
    let(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox, account: account) }
    let(:message) { create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account) }
    let(:service) { described_class.new(message: message) }
    let(:plain_keys) { {} }
    let(:absent_keys) { %i[messaging_type tag] }
    let(:transport) { { 'message_id' => 'mid.sent' } }

    before do
      allow(Facebook::Messenger::Configuration::AppSecretProofCalculator).to receive(:call).and_return('app_secret_proof')
      allow(HTTParty).to receive(:post) do |_url, **options|
        bodies << options[:body]
        instance_double(HTTParty::Response, :success? => !transport.key?('error'), :parsed_response => transport)
      end
    end

    it_behaves_like 'a service that seals only what a person wrote'

    context 'when Meta refuses the send for being out of window' do
      let(:transport) { window_refusal }

      it_behaves_like 'a service that explains a closed window'
    end

    it 'leaves a token refusal as upstream writes it, on the page channel too' do
      human_agent_feature(true)
      allow(HTTParty).to receive(:post).and_return(
        instance_double(HTTParty::Response, :success? => false, :parsed_response => token_refusal)
      )

      service.perform

      expect(message.reload).to have_attributes(status: 'failed', external_error: '190 - Error validating access token: Session has expired')
      expect(channel.reload.authorization_error_count).to eq(1)
    end
  end

  describe Facebook::SendOnFacebookService do
    # Declared before the channel: creating a page channel subscribes to Meta's webhooks, and a
    # `let!` registers its hook where it is written.
    before do
      allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
      allow(Facebook::Messenger::Bot).to receive(:deliver) do |params, **_options|
        bodies << params
        raise refusal if refusal

        { message_id: 'mid.sent' }.to_json
      end
    end

    let!(:channel) { create(:channel_facebook_page, account: account) }
    let!(:inbox) { create(:inbox, channel: channel, account: account, greeting_enabled: false) }
    let!(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
    let(:conversation) { create(:conversation, contact: contact, inbox: inbox, contact_inbox: contact_inbox, account: account) }
    let(:message) { create(:message, message_type: :outgoing, conversation: conversation, inbox: inbox, account: account) }
    let(:service) { described_class.new(message: message) }
    let(:plain_keys) { { messaging_type: 'RESPONSE' } }
    let(:absent_keys) { %i[tag] }
    let(:refusal) { nil }

    it_behaves_like 'a service that seals only what a person wrote'

    context 'when Meta refuses the send for being out of window' do
      let(:refusal) { Facebook::Messenger::FacebookError.new(window_refusal['error']) }

      it_behaves_like 'a service that explains a closed window'

      it 'stops at the first refusal instead of offering every attachment to a closed window' do
        message.attachments.new(account_id: account.id, file_type: :image)
               .file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        message.save!

        service.perform

        expect(bodies.size).to eq(1)
        expect(message.reload.external_error).to eq(I18n.with_locale(:pt_BR) { I18n.t('errors.meta.messaging_window_closed') })
      end
    end

    it 'leaves a token refusal as upstream writes it, reauthorization counter included' do
      human_agent_feature(true)
      allow(Facebook::Messenger::Bot).to receive(:deliver)
        .and_raise(Facebook::Messenger::FacebookError.new(token_refusal['error']))

      service.perform

      expect(message.reload).to have_attributes(status: 'failed', external_error: 'Error validating access token: Session has expired')
      expect(channel.reload.authorization_error_count).to eq(1)
    end
  end

  describe 'the refusal it recognizes' do
    it 'reads Messenger and Instagram out-of-window subcodes' do
      expect(MetaHumanAgent.window_closed?(code: 10, subcode: 2_018_278, text: 'anything')).to be(true)
      expect(MetaHumanAgent.window_closed?(code: 10, subcode: 2_534_022, text: 'anything')).to be(true)
    end

    it 'falls back to Meta wording on a subcode we never saw, since there is no bench to learn it on' do
      expect(MetaHumanAgent.window_closed?(code: 10, subcode: nil,
                                           text: '(#10) This message is sent outside of allowed window.')).to be(true)
    end

    it 'leaves other code 10 refusals alone' do
      expect(MetaHumanAgent.window_closed?(code: 10, subcode: 2_018_065,
                                           text: 'Application does not have permission for this action')).to be(false)
    end

    it 'does not read the window subcode under another code' do
      expect(MetaHumanAgent.window_closed?(code: 100, subcode: 2_018_278, text: 'anything')).to be(false)
    end

    it 'says no when Meta sent no code at all' do
      expect(MetaHumanAgent.window_closed?(code: nil, subcode: nil, text: nil)).to be(false)
    end
  end

  describe 'the wiring' do
    it 'sits in front of the Messenger service for the refusal' do
      ancestors = Facebook::SendOnFacebookService.ancestors
      expect(ancestors.index(MetaHumanAgent::FacebookWindowError)).to be < ancestors.index(Facebook::SendOnFacebookService)
      expect(Facebook::SendOnFacebookService.private_method_defined?(:deliver_message)).to be(true)
    end

    it 'reads the Instagram refusal on the base class, which is where both services parse it' do
      ancestors = Instagram::BaseSendService.ancestors
      expect(ancestors.index(MetaHumanAgent::InstagramWindowError)).to be < ancestors.index(Instagram::BaseSendService)
      expect(Instagram::BaseSendService.private_method_defined?(:external_error)).to be(true)
    end
  end
end
