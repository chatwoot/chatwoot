module Twilio
  module REST
    class Api < ApiBase
      ##
      # Account provided as the authenticating account
      def account
        self.v2010.account
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   resource.
      # @return [Twilio::REST::Api::V2010::AccountInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountList]
      def accounts(sid=:unset)
        self.v2010.accounts(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Address resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::AddressInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::AddressList]
      def addresses(sid=:unset)
        warn "addresses is deprecated. Use account.addresses instead."
        self.account.addresses(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Application resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::ApplicationInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::ApplicationList]
      def applications(sid=:unset)
        warn "applications is deprecated. Use account.applications instead."
        self.account.applications(sid)
      end

      ##
      # @param [String] connect_app_sid The SID that we assigned to the Connect App.
      # @return [Twilio::REST::Api::V2010::AccountContext::AuthorizedConnectAppInstance] if connect_app_sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::AuthorizedConnectAppList]
      def authorized_connect_apps(connect_app_sid=:unset)
        warn "authorized_connect_apps is deprecated. Use account.authorized_connect_apps instead."
        self.account.authorized_connect_apps(connect_app_sid)
      end

      ##
      # @param [String] country_code The
      #   {ISO-3166-1}[https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2] country code of
      #   the country.
      # @return [Twilio::REST::Api::V2010::AccountContext::AvailablePhoneNumberCountryInstance] if country_code was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::AvailablePhoneNumberCountryList]
      def available_phone_numbers(country_code=:unset)
        warn "available_phone_numbers is deprecated. Use account.available_phone_numbers instead."
        self.account.available_phone_numbers(country_code)
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::BalanceInstance]
      def balance
        warn "balance is deprecated. Use account.balance instead."
        self.account.balance()
      end

      ##
      # @param [String] sid The unique string that we created to identify this Call
      #   resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::CallInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::CallList]
      def calls(sid=:unset)
        warn "calls is deprecated. Use account.calls instead."
        self.account.calls(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify this
      #   Conference resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::ConferenceInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::ConferenceList]
      def conferences(sid=:unset)
        warn "conferences is deprecated. Use account.conferences instead."
        self.account.conferences(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   ConnectApp resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::ConnectAppInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::ConnectAppList]
      def connect_apps(sid=:unset)
        warn "connect_apps is deprecated. Use account.connect_apps instead."
        self.account.connect_apps(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify this
      #   IncomingPhoneNumber resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::IncomingPhoneNumberList]
      def incoming_phone_numbers(sid=:unset)
        warn "incoming_phone_numbers is deprecated. Use account.incoming_phone_numbers instead."
        self.account.incoming_phone_numbers(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the Key
      #   resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::KeyInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::KeyList]
      def keys(sid=:unset)
        warn "keys is deprecated. Use account.keys instead."
        self.account.keys(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Message resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::MessageInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::MessageList]
      def messages(sid=:unset)
        warn "messages is deprecated. Use account.messages instead."
        self.account.messages(sid)
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::NewKeyInstance]
      def new_keys
        warn "new_keys is deprecated. Use account.new_keys instead."
        self.account.new_keys()
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::NewSigningKeyInstance]
      def new_signing_keys
        warn "new_signing_keys is deprecated. Use account.new_signing_keys instead."
        self.account.new_signing_keys()
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Notification resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::NotificationInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::NotificationList]
      def notifications(sid=:unset)
        warn "notifications is deprecated. Use account.notifications instead."
        self.account.notifications(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   OutgoingCallerId resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::OutgoingCallerIdInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::OutgoingCallerIdList]
      def outgoing_caller_ids(sid=:unset)
        warn "outgoing_caller_ids is deprecated. Use account.outgoing_caller_ids instead."
        self.account.outgoing_caller_ids(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify this
      #   Queue resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::QueueInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::QueueList]
      def queues(sid=:unset)
        warn "queues is deprecated. Use account.queues instead."
        self.account.queues(sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Recording resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::RecordingInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::RecordingList]
      def recordings(sid=:unset)
        warn "recordings is deprecated. Use account.recordings instead."
        self.account.recordings(sid)
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Api::V2010::AccountContext::SigningKeyInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::SigningKeyList]
      def signing_keys(sid=:unset)
        warn "signing_keys is deprecated. Use account.signing_keys instead."
        self.account.signing_keys(sid)
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::SipInstance]
      def sip
        warn "sip is deprecated. Use account.sip instead."
        self.account.sip()
      end

      ##
      # @param [String] sid The unique string that that we created to identify this
      #   ShortCode resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::ShortCodeInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::ShortCodeList]
      def short_codes(sid=:unset)
        warn "short_codes is deprecated. Use account.short_codes instead."
        self.account.short_codes(sid)
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::TokenInstance]
      def tokens
        warn "tokens is deprecated. Use account.tokens instead."
        self.account.tokens()
      end

      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Transcription resource.
      # @return [Twilio::REST::Api::V2010::AccountContext::TranscriptionInstance] if sid was passed.
      # @return [Twilio::REST::Api::V2010::AccountContext::TranscriptionList]
      def transcriptions(sid=:unset)
        warn "transcriptions is deprecated. Use account.transcriptions instead."
        self.account.transcriptions(sid)
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::UsageInstance]
      def usage
        warn "usage is deprecated. Use account.usage instead."
        self.account.usage()
      end

      ##
      # @return [Twilio::REST::Api::V2010::AccountContext::ValidationRequestInstance]
      def validation_requests
        warn "validation_requests is deprecated. Use account.validation_requests instead."
        self.account.validation_requests()
      end
    end
  end
end