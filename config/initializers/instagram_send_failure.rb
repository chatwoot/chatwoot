# `Instagram::BaseSendService#perform_reply` rescues StandardError and hands it to
# `handle_error`, which only reports to the exception tracker. Nothing marks the message, so an
# unexpected error on this path ends with the row still on `sent`: no raised job, no Sidekiq
# retry, no dead-set entry, and an agent looking at a reply that appears delivered and never
# left. Measured with FB_APP_SECRET absent, which makes the app secret proof raise: zero
# requests to Meta, no exception out of the service, status `sent`, `external_error` nil.
#
# Upstream treats the missing config itself as a setup problem (chatwoot/chatwoot#12066, closed
# on that answer), and that is not relitigated here. What this fixes is the silence, for every
# unexpected error on the path and not just that one.
#
# Conditional on nothing having left yet, and that condition is the delicate part rather than a
# formality: `perform_reply` offers attachments before content and `process_response` writes
# `source_id` on each success, so a message can be half delivered when something raises. Marking
# that failed invites a resend and puts the first attachment in front of the contact twice.
# `SendReplyJob.fail_email_message` guards on the same field for the same reason.
#
# Declared here instead of as an autoloaded class, for the reason import_guards.rb gives: a
# reloadable module handed to `prepend` is a new object after every reload, so the ancestor chain
# would grow one copy per edit in development. Prepended rather than edited in:
# `app/services/instagram/base_send_service.rb` is byte-identical to upstream, and a guard clause
# inside it would be a conflict on every sync.
module InstagramSendFailure
  class << self
    # Deliberately vague about whether the message arrived, because this covers every unexpected
    # error on the path and some of them (a timeout mid-flight) leave that genuinely unknown.
    # Claiming it did not arrive would be the wording that produces duplicates.
    def reason(message)
      I18n.with_locale(locale_for(message.account)) { I18n.t('errors.meta.send_failed') }
    end

    # Same guard, and the same reason, as MessageTemplates::Template::CsatSurvey#account_locale.
    # It matters more here: this runs inside a rescue, so an InvalidLocale raised while building
    # the sentence would escape `handle_error` and re-open the silence it exists to close.
    def locale_for(account)
      I18n.available_locales.map(&:to_s).include?(account.locale) ? account.locale : I18n.default_locale
    end
  end

  module MarkFailed
    private

    def handle_error(error)
      super

      message.with_lock do
        # Something already left: the row is not ours to fail.
        next if message.source_id.present?
        # Meta already said why, in `process_response`, and its wording names the actual problem.
        next if message.external_error.present?

        Messages::StatusUpdateService.new(message, 'failed', InstagramSendFailure.reason(message)).perform
      end
    end
  end
end

Rails.application.config.to_prepare do
  Instagram::BaseSendService.prepend(InstagramSendFailure::MarkFailed)
end
