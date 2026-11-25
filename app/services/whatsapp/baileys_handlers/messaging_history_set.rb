# WhatsApp's own account of what this inbox missed, and of what came before it existed.
#
# The phone sends this on its own after a pairing, and again after every reconnect, and it
# answers an explicit request with it. Baileys types the dump, which is the fact that makes
# this provider worth keeping alive for one more feature: `RECENT` is WhatsApp replaying
# what arrived while the device was offline, so a Baileys inbox can recover a disconnect
# that no other provider we serve can.
#
# The dump arrives in frames (see historySync.ts on the bridge), each one a slice of one
# `messaging-history.set` under the byte budget. Every frame is filed on its own: order
# between them carries no meaning, since the importer sorts by timestamp and deduplicates
# by provider id.
module Whatsapp::BaileysHandlers::MessagingHistorySet
  include Whatsapp::BaileysHandlers::Helpers

  # proto.HistorySync.HistorySyncType, as Baileys forwards it.
  INITIAL_BOOTSTRAP = 0
  INITIAL_STATUS_V3 = 1
  FULL = 2
  RECENT = 3
  PUSH_NAME = 4
  NON_BLOCKING_DATA = 5
  ON_DEMAND = 6

  # The four that carry conversation. The three that are left are the phone's status
  # updates, its address book display names and an app-state blob: none of them is a
  # message, and filing them would put empty rows in somebody's inbox.
  IMPORTABLE_SYNC_TYPES = [INITIAL_BOOTSTRAP, FULL, RECENT, ON_DEMAND].freeze

  # WhatsApp's own account, the one that sends service notices. Baileys' `shouldIgnoreJid`
  # never sees a history dump -- it filters live traffic only -- so a full sync replays
  # years of those, and each one asks the legacy pipeline to build a contact whose phone
  # number is `+0`. Measured on a real pairing: 79 rows across 8 chats, every one of them
  # a job dying on `Phone number should be in e164 format`.
  SYSTEM_JID = '0@s.whatsapp.net'.freeze

  private

  def process_messaging_history_set
    return unless inbox.channel.session_capabilities.include?('history_sync')

    data = processed_params[:data]
    sync_type = data[:syncType]
    return unless importable_sync_type?(sync_type)

    mark_exhausted(data)

    batches = importable_batches(data)
    return if batches.empty?

    # Read here, once, before any job runs. Each chat is imported by its own worker, and a
    # boundary read inside them would be measured against whatever the workers that went
    # first had already written.
    watermark = Whatsapp::Session::Inbound::Coverage.watermark(inbox)
    requested = requested?(sync_type)
    # ON_DEMAND exists only as an answer to a request we sent, and the only thing that
    # sends one is an operator pressing for older messages inside a thread. So the type is
    # already the fact that somebody is watching this land, and the archive it carries is
    # announced rather than filed in silence -- otherwise the press does nothing visible
    # until the page is reloaded. Every other type is the phone volunteering.
    announce = sync_type.to_i == ON_DEMAND
    # What the groups in this dump are called. A dump strips `groupName` from the messages,
    # so without this an imported group is filed under its own jid and stays that way until
    # somebody writes in it: 34 of 46 groups on a real pairing.
    group_names = Array(data[:groupNames]).to_h
    batches.each do |jid, batch|
      Whatsapp::Baileys::HistoryImportJob.perform_later(inbox, batch, watermark, requested, **filing(announce, group_names[jid]))
    end
  end

  # One chat's name and not the dump's whole map: a job is enqueued per chat per frame, so
  # the map would be serialized into Redis once per batch, and most of those batches are
  # not even groups.
  #
  # Left off entirely when there is nothing to say. A worker from before this keyword raises
  # ArgumentError on it, and that covers the one window where the two are guaranteed to
  # disagree: this half and the bridge half ship separately, so between them every dump
  # arrives with no subjects at all.
  #
  # It does not cover a rollback or the overlap of a deploy, where a named group can reach a
  # worker that predates the keyword. That batch fails and lands in the dead set with its
  # payload intact, to be re-driven; a signature is a serialization contract, and the only
  # thing that would close that window is shipping the tolerant worker a release ahead of
  # the producer.
  def filing(announce, group_name)
    filing = { announce: announce }
    filing[:group_name] = group_name if group_name.present?
    filing
  end

  # WhatsApp saying a chat has nothing older left, which it says on the answer to a
  # request and nowhere else -- the chat records in a volunteered dump never carry it.
  # Recorded on the thread so the control that sent the request can stop offering and say
  # what WhatsApp Web says in the same place: that the rest lives on the phone.
  #
  # Filed against the contact rather than one thread, because the anchor a request walks
  # back from is the oldest message the inbox holds for that chat across every thread it
  # opened. The answer is about the chat; which thread the operator happened to be reading
  # when they asked is not part of it.
  def mark_exhausted(data)
    Array(data[:exhausted]).each do |jid|
      conversations_for_chat(jid).each { |conversation| flag_exhausted(conversation) }
    end
  end

  # The answer is addressed the way WhatsApp holds the chat, which is not always the way the
  # request was addressed: a request sent to a LID comes back answered as
  # `<phone>@s.whatsapp.net`. Matching the id by equality only lands when the row happens to
  # have been keyed by the same half of the pair the answer used, and a row on a Baileys
  # inbox can legitimately be keyed by either.
  #
  # `ContactLookup` is where that question already has one answer, covering the three keys
  # that can hold the same person: the id as given, the other ninth-digit spelling of the
  # number, and the phone on the contact itself, which is all that survives once
  # consolidation re-keys the row to a LID. Asking it here rather than writing a fourth
  # version is the point -- the miss was never in the logic, it was in there being several.
  def conversations_for_chat(jid)
    party = party_for(jid)
    contact_inbox = Whatsapp::Session::Inbound::ContactLookup.find(inbox: inbox, party: party)
    return Conversation.none if contact_inbox.blank?

    inbox.conversations.where(contact_id: contact_inbox.contact_id)
  end

  # Resolved per call rather than aliased to a constant: a constant pointing at another
  # file's class keeps the pre-reload object, and in development that object is the one
  # Zeitwerk already discarded.
  def model = Whatsapp::Session::Model

  # One jid names one half of the pair and never says what the other is, so which half it
  # is has to come from the domain: `@lid` is the LID namespace and everything else is the
  # phone one.
  def party_for(jid)
    id, domain = jid.to_s.split('@')
    return if id.blank?

    domain == 'lid' ? model::Party.new(lid: id) : model::Party.new(phone: id)
  end

  def flag_exhausted(conversation)
    return if conversation.additional_attributes['history_exhausted']

    conversation.update!(additional_attributes: conversation.additional_attributes.merge('history_exhausted' => true))
  end

  # One batch per chat, minus the ones no contact can be built from.
  def importable_batches(data)
    Array(data[:messages])
      .group_by { |message| message.dig(:key, :remoteJid) }
      .reject { |jid, _| jid.blank? || jid == SYSTEM_JID }
  end

  # An absent type is taken as importable: the bridge may predate the field, and Coverage
  # decides what happens to the pile either way. Only a type we recognise as carrying no
  # conversation is dropped.
  def importable_sync_type?(sync_type)
    return true if sync_type.nil?

    IMPORTABLE_SYNC_TYPES.include?(sync_type.to_i)
  end

  # Whether anybody asked for this pile, which decides how much of it is kept rather than
  # whether any of it is. Three ways to have asked, and the first is the phone answering a
  # question we put to it: `fetchMessageHistory` comes back typed ON_DEMAND, so the request
  # identifies its own answer and no window has to hold that fact.
  #
  # The other two mirror the session layer exactly: standing consent on the inbox, or the
  # window a press of the button opens. The window is re-opened while an answer is still
  # arriving, because a dump comes in several frames and one closing between two of them
  # would drop the tail of the import it authorised.
  def requested?(sync_type)
    return true if sync_type.to_i == ON_DEMAND
    return true if inbox.channel.provider_service.try(:history_sync?)
    return false unless Whatsapp::Session::HistoryBackfill.pending?(inbox.channel)

    Whatsapp::Session::HistoryBackfill.open!(inbox.channel)
    true
  end
end
