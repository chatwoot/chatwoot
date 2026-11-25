# The WhatsApp id a send will use, chosen here instead of by the provider.
#
# `source_id` can only be written from the send response, so a send whose response never
# arrives (socket drop, read timeout, worker restart) leaves nothing to recognize the
# echo of our own message by: it lands as a fresh "sent from the phone" message.
# Reserving the id up front closes that window, and a retry reuses it so WhatsApp still
# sees a single message.
#
# The shape mirrors what WhatsApp clients generate: the "3EB0" prefix and 18 uppercase
# hex characters.
module Whatsapp::Session::Outbound::SourceIdReservation
  PREFIX = '3EB0'.freeze

  module_function

  def generate
    "#{PREFIX}#{SecureRandom.hex(9).upcase}"
  end

  # Read-or-generate runs under the row lock, which re-reads the row: a reaction toggle in
  # the meantime clears the reservation precisely to force a fresh id, and sending under a
  # stale one would resend the previous reaction with an unmatchable echo.
  #
  # Written with update_columns: the reservation is bookkeeping for a send that has not
  # happened yet, so it must not fire message.updated (cable, webhooks, agent bots, search
  # reindex) nor bump updated_at.
  def reserve(message)
    message.with_lock do
      next message.pending_source_id if message.pending_source_id.present?

      message.pending_source_id = generate
      message.update_columns(content_attributes: message.content_attributes) # rubocop:disable Rails/SkipsModelValidations
      message.pending_source_id
    end
  end

  # Writes what a send came back with, and says what the caller still owes:
  #
  #   :stale   the response belongs to a send this row has moved on from; nothing written
  #   :revoke  the id was assigned here and the message was deleted meanwhile
  #   :written assigned or updated, nothing else to do
  #
  # Three writers can fill `source_id` on one send: the send response, the echo of the same
  # message arriving from WhatsApp, and the delete endpoint reading it. Provider revocation
  # is not idempotent, so exactly one of them may enqueue it, and it belongs to whoever
  # moves the column from blank to set while the message is deleted. Both halves of that
  # answer are read inside the row lock: deciding before it, or re-reading `deleted` after
  # it, lets the delete endpoint slip into the gap and revoke the same message twice.
  #
  # `reservation` fences the write to the send it came from. Toggling a reaction rewrites
  # the same row and clears its reservation on purpose, so the replacement is sent rather
  # than mistaken for an echo; a slow response from the previous emoji landing after that
  # would otherwise write its id back, and SendOnChannelService would skip the replacement
  # as something the provider already has.
  #
  # The two lines before the lock are what `Message#update_under_lock!` does, for the same
  # reason: `lock!` refuses a record with unsaved changes, and the stale content_attributes
  # hash must never be the thing that gets written back.
  def assign(message, attributes, reservation: nil)
    message.restore_attributes(['content_attributes']) if message.content_attributes_changed?
    message.save! if message.changed?

    outcome = nil
    message.with_lock { outcome = write(message, attributes, reservation) }
    outcome
  end

  def write(message, attributes, reservation)
    return :stale if reservation.present? && message.pending_source_id != reservation

    assigned_here = message.source_id.blank? && attributes[:source_id].present?
    message.update!(attributes.merge(assigned_here ? send_confirmation(message) : {}))
    assigned_here && revoked?(message) ? :revoke : :written
  end

  # A removed reaction is deleted from the start, and the empty emoji just sent is what
  # clears it. Revoking on top of that would ask the provider to delete the reaction
  # message itself, which is a different thing and one the contact never saw.
  def revoked?(message) = message.deleted? && !message.removed_reaction?

  # Filling source_id is proof the message exists on WhatsApp, so it also retires a
  # failure recorded while it did not. StatusTransition.fail_send only ever writes one
  # while source_id is blank, so a `failed` still standing here is exactly that: our
  # verdict about a send we stopped waiting on, not WhatsApp's about the message.
  #
  # Atomic with the source_id write on purpose. Waiting for a delivery receipt to promote
  # it (which StatusTransition does allow) leaves a window where the message is proven to
  # exist and still shows Retry — and Retry clears the reservation and sends a fresh id,
  # producing the duplicate this whole reservation exists to prevent. external_error goes
  # with it, since that is what the dashboard reads to decide between resend and recreate.
  def send_confirmation(message)
    return {} unless message.status == 'failed'

    { status: :sent, external_error: nil }
  end
end
