require 'rails_helper'

RSpec.describe Conversations::MessageWindowService do
  describe 'on API channels' do
    let!(:api_channel) { create(:channel_api, additional_attributes: {}) }
    let!(:api_channel_with_limit) { create(:channel_api, additional_attributes: { agent_reply_time_window: '12' }) }

    context 'when agent_reply_time_window is not configured' do
      it 'return true irrespective of the last message time' do
        conversation = create(:conversation, inbox: api_channel.inbox)
        create(
          :message,
          account: conversation.account,
          inbox: api_channel.inbox,
          conversation: conversation,
          created_at: 13.hours.ago
        )
        service = described_class.new(conversation)

        expect(api_channel.additional_attributes['agent_reply_time_window']).to be_nil
        expect(service.can_reply?).to be true
      end
    end

    context 'when agent_reply_time_window is configured' do
      it 'return false if it is outside of agent_reply_time_window' do
        conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
        create(
          :message,
          account: conversation.account,
          inbox: api_channel_with_limit.inbox,
          conversation: conversation,
          created_at: 13.hours.ago
        )
        service = described_class.new(conversation)

        expect(api_channel_with_limit.additional_attributes['agent_reply_time_window']).to eq '12'
        expect(service.can_reply?).to be false
      end

      it 'return true if it is inside of agent_reply_time_window' do
        conversation = create(:conversation, inbox: api_channel_with_limit.inbox)
        create(
          :message,
          account: conversation.account,
          inbox: api_channel_with_limit.inbox,
          conversation: conversation
        )
        service = described_class.new(conversation)

        expect(service.can_reply?).to be true
      end
    end
  end

  describe 'on Facebook channels' do
    before do
      stub_request(:post, /graph.facebook.com/)
    end

    let!(:facebook_channel) { create(:channel_facebook_page) }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: facebook_channel.account) }
    let!(:conversation) { create(:conversation, inbox: facebook_inbox, account: facebook_channel.account) }

    context 'when the HUMAN_AGENT is enabled' do
      it 'return false if the last message is outgoing' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return true if the last message is incoming and within the messaging window (with in 24 hours)' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'return true if the last message is incoming and within the messaging window (with in 7 days)' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 5.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'return false if the last message is incoming and outside the messaging window (8 days ago )' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 8.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return true if last message is outgoing but previous incoming message is within window' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            message_type: :incoming,
            created_at: 6.hours.ago
          )

          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            message_type: :outgoing,
            created_at: 1.hour.ago
          )

          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'considers only the last incoming message for determining time window' do
        with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'true' do
          # Old message outside window
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 10.days.ago
          )

          # Recent message within window
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 6.hours.ago
          )

          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end
    end

    context 'when the HUMAN_AGENT is disabled' do
      with_modified_env ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT: 'false' do
        it 'return false if the last message is outgoing' do
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end

        it 'return false if the last message is incoming and outside the messaging window ( 8 days ago )' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 4.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end

        it 'return true if the last message is incoming and within the messaging window (24 hours limit)' do
          create(
            :message,
            account: conversation.account,
            inbox: facebook_inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end
    end
  end

  describe 'on Instagram channels' do
    let!(:instagram_channel) { create(:channel_instagram) }
    let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: instagram_channel.account) }
    let!(:conversation) { create(:conversation, inbox: instagram_inbox, account: instagram_channel.account) }

    context 'when the HUMAN_AGENT is enabled' do
      it 'return false if the last message is outgoing' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return true if the last message is incoming and within the messaging window (with in 24 hours)' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'return true if the last message is incoming and within the messaging window (with in 7 days)' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 6.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'return false if the last message is incoming and outside the messaging window (8 days ago)' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 8.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return true if last message is outgoing but previous incoming message is within window' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            message_type: :incoming,
            created_at: 6.hours.ago
          )

          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            message_type: :outgoing,
            created_at: 1.hour.ago
          )

          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'considers only the last incoming message for determining time window' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          # Old message outside window
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 10.days.ago
          )

          # Recent message within window
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 6.hours.ago
          )

          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end

      it 'return true if the last message is incoming and exactly at the edge of 24-hour window with HUMAN_AGENT disabled' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'true' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 24.hours.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end
    end

    context 'when the HUMAN_AGENT is disabled' do
      it 'return false if the last message is outgoing' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'false' do
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return false if the last message is incoming and outside the messaging window (8 days ago)' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'false' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 9.days.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be false
        end
      end

      it 'return true if the last message is incoming and within the messaging window (24 hours limit)' do
        with_modified_env ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT: 'false' do
          create(
            :message,
            account: conversation.account,
            inbox: instagram_inbox,
            conversation: conversation,
            created_at: 13.hours.ago
          )
          service = described_class.new(conversation)
          expect(service.can_reply?).to be true
        end
      end
    end
  end

  describe 'on WhatsApp Cloud channels' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: whatsapp_channel.account) }
    let!(:conversation) { create(:conversation, inbox: whatsapp_inbox, account: whatsapp_channel.account) }

    it 'return false if the last message is outgoing' do
      service = described_class.new(conversation)
      expect(service.can_reply?).to be false
    end

    it 'return true if the last message is incoming and within the messaging window (with in 24 hours)' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end

    it 'return false if the last message is incoming and outside the messaging window (24 hours limit)' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 25.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be false
    end

    it 'return true if last message is outgoing but previous incoming message is within window' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        message_type: :incoming,
        created_at: 6.hours.ago
      )

      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        message_type: :outgoing,
        created_at: 1.hour.ago
      )

      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end

    it 'considers only the last incoming message for determining time window' do
      # Old message outside window
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 10.days.ago
      )

      # Recent message within window
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 6.hours.ago
      )

      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on WhatsApp Baileys channels' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', sync_templates: false, validate_provider_config: false) }
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: whatsapp_channel.account) }
    let!(:conversation) { create(:conversation, inbox: whatsapp_inbox, account: whatsapp_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 25.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on Web widget channels' do
    let!(:widget_channel) { create(:channel_widget) }
    let!(:widget_inbox) { create(:inbox, channel: widget_channel, account: widget_channel.account) }
    let!(:conversation) { create(:conversation, inbox: widget_inbox, account: widget_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: widget_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on SMS channels' do
    let!(:sms_channel) { create(:channel_sms) }
    let!(:sms_inbox) { create(:inbox, channel: sms_channel, account: sms_channel.account) }
    let!(:conversation) { create(:conversation, inbox: sms_inbox, account: sms_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: sms_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on Telegram channels' do
    let!(:telegram_channel) { create(:channel_telegram) }
    let!(:telegram_inbox) { create(:inbox, channel: telegram_channel, account: telegram_channel.account) }
    let!(:conversation) { create(:conversation, inbox: telegram_inbox, account: telegram_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: telegram_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on Email channels' do
    let!(:email_channel) { create(:channel_email) }
    let!(:email_inbox) { create(:inbox, channel: email_channel, account: email_channel.account) }
    let!(:conversation) { create(:conversation, inbox: email_inbox, account: email_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: email_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on Line channels' do
    let!(:line_channel) { create(:channel_line) }
    let!(:line_inbox) { create(:inbox, channel: line_channel, account: line_channel.account) }
    let!(:conversation) { create(:conversation, inbox: line_inbox, account: line_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: line_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on Twilio SMS channels' do
    let!(:twilio_sms_channel) { create(:channel_twilio_sms) }
    let!(:twilio_sms_inbox) { create(:inbox, channel: twilio_sms_channel, account: twilio_sms_channel.account) }
    let!(:conversation) { create(:conversation, inbox: twilio_sms_inbox, account: twilio_sms_channel.account) }

    it 'return true irrespective of the last message time' do
      create(
        :message,
        account: conversation.account,
        inbox: twilio_sms_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end

  describe 'on WhatsApp Twilio channels' do
    let!(:whatsapp_channel) { create(:channel_twilio_sms, medium: :whatsapp) }
    let!(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: whatsapp_channel.account) }
    let!(:conversation) { create(:conversation, inbox: whatsapp_inbox, account: whatsapp_channel.account) }

    it 'return false if the last message is outgoing' do
      service = described_class.new(conversation)
      expect(service.can_reply?).to be false
    end

    it 'return true if the last message is incoming and within the messaging window (with in 24 hours)' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 13.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end

    it 'return false if the last message is incoming and outside the messaging window (24 hours limit)' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 25.hours.ago
      )
      service = described_class.new(conversation)
      expect(service.can_reply?).to be false
    end

    it 'return true if last message is outgoing but previous incoming message is within window' do
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        message_type: :incoming,
        created_at: 6.hours.ago
      )

      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        message_type: :outgoing,
        created_at: 1.hour.ago
      )

      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end

    it 'considers only the last incoming message for determining time window' do
      # Old message outside window
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 10.days.ago
      )

      # Recent message within window
      create(
        :message,
        account: conversation.account,
        inbox: whatsapp_inbox,
        conversation: conversation,
        created_at: 6.hours.ago
      )

      service = described_class.new(conversation)
      expect(service.can_reply?).to be true
    end
  end
end
