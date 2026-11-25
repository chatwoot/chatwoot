# Meta grants the Human Agent feature so that *a person* can answer a contact up to seven days
# after their last message; a reply sent by anything else belongs in the 24-hour window, as an
# ordinary response. Since v4.19.0 upstream only stamps `tag: HUMAN_AGENT` on a reply a User wrote
# outside that window (Facebook::HumanAgentTagHelpers), which is the rule the fork used to enforce
# here with a guard of its own.
#
# What is left is the other half: Meta's refusal for a closed window, which a bot meets whenever it
# answers past 24 hours, is persisted as a sentence the agent can act on, in the account's language,
# instead of "10 - (#10) This message is sent outside of allowed window. Learn more about...".
#
# Declared here instead of as autoloaded classes, and for the reason import_guards.rb gives: a
# reloadable module handed to `prepend` is a new object after every reload, so the ancestor chain
# would grow one copy per edit in development. Prepended rather than edited into the services:
# the targets are files the upstream sync rewrites, and a guard clause inside them is a conflict
# on every merge.
module MetaHumanAgent
  WINDOW_CLOSED_CODE = 10
  # 2018278 on Messenger, 2534022 on Instagram. Meta documents neither; both come from
  # third-party error references, which is also why the wording below is kept as a fallback.
  WINDOW_CLOSED_SUBCODES = [2_018_278, 2_534_022].freeze
  WINDOW_CLOSED_TEXT = /outside of allowed window/i

  class << self
    def human_sender?(message)
      message.sender.is_a?(User)
    end

    # Anchored on code 10, so the wording fallback cannot swallow an unrelated refusal: a code 10
    # that says it is outside the allowed window *is* this refusal. It earns its place because
    # there is no Meta bench here to discover a third subcode on, and without it an unlisted
    # subcode would silently fall back to the raw string.
    # Both values come off a parsed JSON body, so they are an Integer or nil, and nil compares
    # and matches its way to false on its own.
    def window_closed?(code:, subcode:, text: nil)
      return false unless code == WINDOW_CLOSED_CODE

      WINDOW_CLOSED_SUBCODES.include?(subcode) || WINDOW_CLOSED_TEXT.match?(text.to_s)
    end

    # Two sentences because the remedy differs: a person can wait for the contact to write again,
    # while a bot's own reply will keep being refused until an agent takes the conversation over.
    # Resolved here rather than read from a constant: this runs in SendReplyJob, on Sidekiq, where
    # nothing sets the locale, and the string is persisted into external_error and rendered to
    # whoever opens the conversation.
    def window_closed_error(message)
      key = human_sender?(message) ? 'messaging_window_closed' : 'messaging_window_closed_for_automation'
      I18n.with_locale(locale_for(message.account)) { I18n.t("errors.meta.#{key}") }
    end

    # Same guard, and the same reason, as MessageTemplates::Template::CsatSurvey#account_locale.
    # It matters more on the Instagram path: `perform_reply` there rescues StandardError into the
    # exception tracker, so an InvalidLocale raised while building this string would swallow the
    # failure and leave the message sitting on `sent` with no reason at all.
    def locale_for(account)
      I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : I18n.default_locale
    end

    def log_refusal(message, code, subcode)
      Rails.logger.warn(
        "[META] message #{message.id} refused for a closed messaging window (code #{code}, subcode #{subcode})"
      )
    end
  end

  # The refusal arrives as a parsed body on this path, which is why the interception sits on the
  # method that turns it into text. Everything that is not this refusal goes to `super`, so a
  # token error still carries Meta's own wording and still trips `channel.authorization_error!`.
  module InstagramWindowError
    private

    def external_error(response)
      code = response.dig('error', 'code')
      subcode = response.dig('error', 'error_subcode')
      return super unless MetaHumanAgent.window_closed?(code: code, subcode: subcode, text: response.dig('error', 'message'))

      MetaHumanAgent.log_refusal(message, code, subcode)
      MetaHumanAgent.window_closed_error(message)
    end
  end

  # The facebook-messenger gem raises on any response carrying an `error`, so this refusal never
  # reaches the service's own `external_error`: it surfaces as a FacebookError in `perform_reply`,
  # whose rescue persists `e.message` verbatim. Caught one frame earlier and handed back with our
  # sentence in place of Meta's, so that the rescue upstream already has does the writing, the
  # attachment loop stops at the first refusal instead of offering each attachment to a window
  # that is closed, and `handle_facebook_error` still sees an untouched token error.
  #
  # This leans on upstream persisting `e.message` rather than, say, "#{e.code} - #{e.message}".
  # The spec pins the stored sentence, so a sync that changes it fails there rather than in
  # production.
  module FacebookWindowError
    private

    def deliver_message(delivery_params)
      super
    rescue Facebook::Messenger::FacebookError => e
      raise unless MetaHumanAgent.window_closed?(code: e.code, subcode: e.subcode, text: e.message)

      MetaHumanAgent.log_refusal(message, e.code, e.subcode)
      raise Facebook::Messenger::FacebookError.new(
        'message' => MetaHumanAgent.window_closed_error(message),
        'type' => e.type,
        'code' => e.code,
        'error_subcode' => e.subcode
      )
    end
  end
end

Rails.application.config.to_prepare do
  Facebook::SendOnFacebookService.prepend(MetaHumanAgent::FacebookWindowError)
  Instagram::BaseSendService.prepend(MetaHumanAgent::InstagramWindowError)
end
