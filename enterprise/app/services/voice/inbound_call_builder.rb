module Voice
  class InboundCallBuilder
    pattr_initialize [:account!, :inbox!, :from_number!, :to_number, :call_sid!]

    attr_reader :conversation, :conference_sid

    def perform
      contact = find_or_create_contact!
      contact_inbox = find_or_create_contact_inbox!(contact)

      @conversation = Conversation.create!(
        account_id:       account.id,
        inbox_id:         inbox.id,
        contact_id:       contact.id,
        contact_inbox_id: contact_inbox.id,
        identifier:       call_sid,
        additional_attributes: {
          'call_direction' => 'inbound',
          'call_status'    => 'ringing'
        }
      )

      @conference_sid = "conf_account_#{account.id}_conv_#{@conversation.display_id || @conversation.id}"

      @conversation.messages.create!(
        account_id:   account.id,
        inbox_id:     inbox.id,
        message_type: :incoming,
        sender:       @conversation.contact,
        content:      'Voice Call',
        content_type: 'voice_call',
        content_attributes: {
          data: {
            call_sid:        call_sid,
            status:          'ringing',
            conversation_id: @conversation.display_id,
            call_direction:  'inbound',
            conference_sid:  @conference_sid,
            from_number:     from_number,
            to_number:       to_number,
            meta:            {
              created_at: Time.now.to_i,
              ringing_at: Time.now.to_i
            }
          }
        }
      )

      self
    end

    def twiml_response
      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Please wait while we connect you to an agent')
      status_url = inbox.channel.try(:voice_status_webhook_url)
      response.dial(statusCallback: status_url,
                    statusCallbackEvent: 'initiated ringing answered completed',
                    statusCallbackMethod: 'POST') do |d|
        d.conference(
          conference_sid,
          startConferenceOnEnter: false,
          endConferenceOnExit:    true,
          beep:                   false,
          muted:                  false,
          waitUrl:                ''
        )
      end
      response.to_s
    end

    private

    def find_or_create_contact!
      account.contacts.find_by(phone_number: from_number) ||
        account.contacts.create!(phone_number: from_number, name: 'Unknown Caller')
    end

    def find_or_create_contact_inbox!(contact)
      ContactInbox.where(contact_id: contact.id, inbox_id: inbox.id, source_id: from_number).first_or_create!
    end
  end
end
