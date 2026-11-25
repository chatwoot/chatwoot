# Single error hierarchy for the session family. Every backend raises one of these, so
# controllers, jobs and the outbound path rescue one namespace instead of a
# provider-specific class.
#
# The legacy Baileys/Z-API errors inherit from ProviderUnavailable, which is what lets
# the existing rescue sites move to this namespace without changing behavior.
#
# `CODE` is the wire code from the contract's error_code enum; Errors.build maps a code
# coming off the wire back to the class.
module Whatsapp::Session::Errors
  class Error < StandardError
    CODE = 'internal'.freeze

    def code
      self.class::CODE
    end

    # Whether running the same command again could produce a different answer. Asked of
    # the exception rather than tested against a list of classes, because a constant
    # holding another file's class keeps the object from before the last reload and
    # `is_a?` against it then answers false without saying why.
    def retryable?
      false
    end
  end

  # The provider could not be reached, or answered with something we cannot act on.
  # Anything the UI should surface as "the WhatsApp connection is not working right now"
  # lives under this class.
  class ProviderUnavailable < Error
    CODE = 'wa_error'.freeze

    # The provider, not the command: the same thing asked again once it is back can work.
    def retryable?
      true
    end
  end

  class Internal < ProviderUnavailable
    CODE = 'internal'.freeze
  end

  class SessionNotFound < ProviderUnavailable
    CODE = 'session_not_found'.freeze
  end

  class NotConnected < ProviderUnavailable
    CODE = 'not_connected'.freeze
  end

  class NotPaired < ProviderUnavailable
    CODE = 'not_paired'.freeze

    # A phone that was logged out stays that way until somebody scans the QR again, so no
    # retry can answer differently. Still a ProviderUnavailable, because the UI says the
    # same thing about it; only the send stops waiting four attempts to say so (#855).
    def retryable?
      false
    end
  end

  class OwnedElsewhere < ProviderUnavailable
    CODE = 'owned_elsewhere'.freeze
  end

  class Quarantined < ProviderUnavailable
    CODE = 'quarantined'.freeze
  end

  class ClientOutdated < ProviderUnavailable
    CODE = 'client_outdated'.freeze
  end

  class Timeout < ProviderUnavailable
    CODE = 'timeout'.freeze
  end

  # A command reached its deadline before the owning instance executed it.
  class Expired < ProviderUnavailable
    CODE = 'expired'.freeze
  end

  class Unauthorized < ProviderUnavailable
    CODE = 'unauthorized'.freeze
  end

  # The backend does not declare the capability the caller asked for.
  class NotSupported < Error
    CODE = 'unsupported'.freeze
  end

  class InvalidPayload < Error
    CODE = 'invalid_payload'.freeze
  end

  class InvalidConfig < Error
    CODE = 'invalid_config'.freeze
  end

  class InvalidEvent < Error
    CODE = 'invalid_event'.freeze
  end

  class RateLimited < Error
    CODE = 'rate_limited'.freeze

    def retryable?
      true
    end
  end

  class MediaTooLarge < Error
    CODE = 'media_too_large'.freeze
  end

  class MediaUnavailable < Error
    CODE = 'media_unavailable'.freeze
  end

  class RecipientNotOnWhatsapp < Error
    CODE = 'recipient_not_on_whatsapp'.freeze
  end

  class GroupParticipantNotAllowed < Error
    CODE = 'group_participant_not_allowed'.freeze
  end

  # A send that reached its deadline without an answer, and that may or may not have arrived.
  # NOT retryable, and that is the whole point of the class: a retry of a send that did arrive
  # puts a second copy in front of the customer, and nothing on this side can tell the two apart.
  # The agent gets the sentence and decides.
  #
  # Deliberately absent from CLASSES below. It is raised here, never received: a connector that
  # sent this code on the wire would be claiming something about our socket, and `build` must not
  # be able to manufacture it out of a string.
  class SendOutcomeUnknown < Error
    CODE = 'send_outcome_unknown'.freeze
  end

  # A teardown (`session.delete`, `session.logout`) that ran out of time while the socket
  # was being dialled: its lock was never free, the unlink was never called, and nothing
  # reached WhatsApp. The connector is certain of that, which is what sets it apart from
  # `timeout`, and it is why the same command again is the whole teardown rather than the
  # half that is left. Whatsapp::Session::TeardownRetry is what acts on it.
  #
  # Not under ProviderUnavailable. The provider answered, and precisely: our own socket was
  # busy. That class carries "the WhatsApp connection is not working right now" to whoever
  # rescues it, and a teardown refused this way is neither a broken connection nor
  # anything an operator should be shown.
  class NotAttempted < Error
    CODE = 'not_attempted'.freeze

    def retryable?
      true
    end
  end

  # A `group.create` whose outcome WhatsApp has not decided yet: the connector recorded the
  # attempt and is waiting for the notification that names which request made which group.
  # The connector backend asks again under the same idempotency key a few times, and this
  # is what is left once it stops, most likely an intent recorded whose request never
  # reached WhatsApp. Not retryable from outside: a caller running the creation again would
  # do it under a fresh key, which is exactly how a second group gets made.
  class NotSettled < Error
    CODE = 'not_settled'.freeze
  end

  # Another worker is already handling this provider message id.
  class MessageAlreadyProcessing < Error
    CODE = 'message_already_processing'.freeze
  end

  # The event refers to a message that is not stored yet. Never on the wire: it is how a
  # transport with no ordering guarantee says "come back in a moment". The ordered
  # transport never raises it, because there the target really is absent.
  class EventOutOfOrder < Error
    CODE = 'event_out_of_order'.freeze

    def retryable?
      true
    end
  end

  CLASSES = [
    ProviderUnavailable, Internal, SessionNotFound, NotConnected, NotPaired, OwnedElsewhere,
    Quarantined, ClientOutdated, Timeout, Expired, Unauthorized, NotSupported, InvalidPayload,
    InvalidConfig, InvalidEvent, RateLimited, MediaTooLarge, MediaUnavailable,
    RecipientNotOnWhatsapp, GroupParticipantNotAllowed, MessageAlreadyProcessing, EventOutOfOrder,
    NotAttempted, NotSettled
  ].freeze

  BY_CODE = CLASSES.index_by { |klass| klass::CODE }.freeze

  # Codes the contract's error_code enum has and this catalogue deliberately leaves to the
  # Internal fallback below. Named so that a code nobody decided about fails the catalogue
  # spec, which reads the vendored enum, instead of degrading in silence.
  #
  # - `provider_unavailable`: a dependency the command named (the storage a send points
  #   its `ref.url` at) did not answer. Internal already is a ProviderUnavailable and
  #   already retryable, so the fallback treats it exactly as a class of its own would;
  #   what a class would add is the code on the exception, which nothing reads yet.
  UNMAPPED_WIRE_CODES = %w[provider_unavailable].freeze

  # A newer connector may answer with a code this version does not know yet. Additive
  # evolution is part of the contract, so an unknown code degrades to Internal instead
  # of blowing up the consumer thread.
  def self.build(code, message = nil)
    BY_CODE.fetch(code, Internal).new(message.presence || code)
  end
end
