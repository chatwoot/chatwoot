# == Schema Information
#
# Table name: messages
#
#  id                        :integer          not null, primary key
#  additional_attributes     :jsonb
#  content                   :text
#  content_attributes        :json
#  content_type              :integer          default("text"), not null
#  external_source_ids       :jsonb
#  message_type              :integer          not null
#  private                   :boolean          default(FALSE), not null
#  processed_message_content :text
#  sender_type               :string
#  sentiment                 :jsonb
#  status                    :integer          default("sent")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer          not null
#  conversation_id           :integer          not null
#  inbox_id                  :integer          not null
#  sender_id                 :bigint
#  source_id                 :text
#
# Indexes
#
#  idx_messages_account_content_created                 (account_id,content_type,created_at)
#  index_messages_on_account_created_type               (account_id,created_at,message_type)
#  index_messages_on_account_id                         (account_id)
#  index_messages_on_account_id_and_inbox_id            (account_id,inbox_id)
#  index_messages_on_additional_attributes_campaign_id  (((additional_attributes -> 'campaign_id'::text))) USING gin
#  index_messages_on_content                            (content) USING gin
#  index_messages_on_conversation_account_type_created  (conversation_id,account_id,message_type,created_at)
#  index_messages_on_conversation_id                    (conversation_id)
#  index_messages_on_created_at                         (created_at)
#  index_messages_on_inbox_id                           (inbox_id)
#  index_messages_on_sender_and_created                 (sender_type,sender_id,created_at)
#  index_messages_on_sender_type_and_sender_id          (sender_type,sender_id)
#  index_messages_on_source_id                          (source_id)
#

class Message < ApplicationRecord
  searchkick callbacks: false if ChatwootApp.advanced_search_allowed?

  include MessageFilterHelpers
  include Liquidable
  include ScheduledMessageHandler
  NUMBER_OF_PERMITTED_ATTACHMENTS = 15
  BOT_SENDER_TYPES = %w[AgentBot Captain::Assistant].freeze

  TEMPLATE_PARAMS_SCHEMA = {
    'type': 'object',
    'properties': {
      'template_params': {
        'type': 'object',
        'properties': {
          'name': { 'type': 'string' },
          'category': { 'type': 'string' },
          'language': { 'type': 'string' },
          'namespace': { 'type': 'string' },
          'content_mode': { 'type': 'string', 'enum': %w[raw_template rendered] },
          'processed_params': { 'type': 'object' }
        },
        'required': %w[name]
      }
    }
  }.to_json.freeze

  before_validation :ensure_content_type
  before_validation :prevent_message_flooding
  before_save :ensure_processed_message_content
  before_save :ensure_in_reply_to

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :conversation_id, presence: true
  validates_with ContentAttributeValidator
  validates_with JsonSchemaValidator,
                 schema: TEMPLATE_PARAMS_SCHEMA,
                 attribute_resolver: ->(record) { record.additional_attributes }

  validates :content_type, presence: true
  validates :content, length: { maximum: 150_000 }
  validates :processed_message_content, length: { maximum: 150_000 }

  # when you have a temperory id in your frontend and want it echoed back via action cable
  attr_accessor :echo_id
  # Transient flag used to skip waiting_since clearing for specific bot/system messages.
  attr_accessor :preserve_waiting_since

  # NOTE: Allow skipping message flooding validation for bulk operations like imports/cloning
  attr_accessor :skip_message_flooding_validation

  # Set by a caller that writes an edit before the channel has taken it, so the announcement waits for
  # the channel's answer instead of going out on the optimistic write. See `#announce_edit`.
  attr_accessor :defer_edit_announcement

  # The digest of the body a recovery brought into this row, written by the WhatsApp session writer in
  # the same save as that body and never taken off. The announcement debt beside it is a debt and comes
  # off as soon as the announcement is enqueued; this is a fact about where the body came from, and it
  # has to outlive the announcement. It is what lets a write-back tell "the body I just restored is the
  # one a recovery brought" from "the body I just restored is an edit somebody made". #666
  RECOVERED_BODY = 'recovered_body'.freeze

  enum :message_type, { incoming: 0, outgoing: 1, activity: 2, template: 3 }
  enum :content_type, {
    text: 0,
    input_text: 1,
    input_textarea: 2,
    input_email: 3,
    input_select: 4,
    cards: 5,
    form: 6,
    article: 7,
    incoming_email: 8,
    input_csat: 9,
    integrations: 10,
    sticker: 11,
    voice_call: 12
  }
  enum :status, { sent: 0, delivered: 1, read: 2, failed: 3 }
  # [:submitted_email, :items, :submitted_values] : Used for bot message types
  # [:email] : Used by conversation_continuity incoming email messages
  # [:in_reply_to] : Used to reply to a particular tweet in threads
  # [:deleted] : Used to denote whether the message was deleted by the agent
  # [:external_created_at] : Can specify if the message was created at a different timestamp externally
  # [:external_error : Can specify if the message creation failed due to an error at external API
  # [:data] : Used for structured content types such as voice_call
  # [:is_reaction] : Used to denote if the message is a reaction and differentiate it from a simple reply message
  # [:is_edited, :previous_content] : Used to indicated edited message and previous content (before edit)
  # [:zapi_args] : Used to pass additional arguments specific to Z-API WhatsApp provider
  # [:referral] : Click-to-WhatsApp ad metadata (source ad, headline, ctwa_clid, ...) attached to the first message after an ad click
  # [:rich] : Structured WhatsApp "rich" message (template/interactive/buttons/list) with title/body/footer/buttons rendered as a card
  # [:deleted_by_contact] : The contact deleted/revoked the message on WhatsApp; we keep the content visible and only flag it
  # [:pending_source_id] : Provider message id reserved before the send (Baileys), used to match the provider echo back to this row
  # [:edited_at] : Provider timestamp (ms) of the edit currently stored, so an edit that arrives out of order is refused
  # [:is_masked] : WhatsApp withheld the content from linked devices (verification codes); set alongside :is_unsupported
  # [:is_view_once] : A view-once message, which WhatsApp does not deliver to linked devices; set alongside :is_unsupported

  store :content_attributes, accessors: [:submitted_email, :items, :submitted_values, :email, :in_reply_to, :deleted,
                                         :external_created_at, :story_sender, :story_id, :external_error,
                                         :translations, :translation_failed, :translation_provider, :source_language,
                                         :in_reply_to_external_id, :is_unsupported, :data,
                                         :is_reaction, :is_edited, :previous_content, :zapi_args, :referral, :rich,
                                         :deleted_by_contact, :pending_source_id, :edited_at, :is_masked, :is_view_once], coder: JSON

  store :external_source_ids, accessors: [:slack], coder: JSON, prefix: :external_source_id

  scope :created_since, ->(datetime) { where('created_at > ?', datetime) }
  scope :chat, -> { where.not(message_type: :activity).where(private: false) }
  scope :non_activity_messages, -> { where.not(message_type: :activity).reorder('created_at desc') }
  scope :today, -> { where("date_trunc('day', created_at) = ?", Date.current) }
  scope :not_forwarded, -> { where("(messages.content_attributes #>> '{}')::jsonb -> 'forwarded_message_id' IS NULL") }
  scope :voice_calls, -> { where(content_type: :voice_call) }
  # Imported messages whose file has not come yet (Whatsapp::Session::HistoryMedia).
  scope :history_media_pending, -> { where("(messages.content_attributes #>> '{}')::jsonb ->> 'history_media' = 'true'") }
  # Excludes reactions whose user-facing state is invisible (toggled off or
  # blank). Used when picking a "last meaningful message" for chat list
  # previews — a removed reaction shouldn't drive the preview text.
  # `#>>'{}'` unwraps the legacy double-encoded `content_attributes` (json
  # column written via `store coder: JSON`) so `->>` can traverse it. The
  # `IS NOT TRUE` guards keep NULL JSON values from collapsing the row under
  # SQL three-valued logic.
  scope :hide_removed_reactions, lambda {
    json_path = "(content_attributes#>>'{}')::jsonb"
    where(
      "((#{json_path})->>'is_reaction' = 'true') IS NOT TRUE " \
      "OR (((#{json_path})->>'deleted' = 'true') IS NOT TRUE AND content IS NOT NULL AND content <> '')"
    )
  }

  # TODO: Get rid of default scope
  # https://stackoverflow.com/a/1834250/939299
  # if you want to change order, use `reorder`
  default_scope { order(created_at: :asc) }

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :sender, polymorphic: true, optional: true

  has_many :attachments, dependent: :destroy, autosave: true, before_add: :validate_attachments_limit
  has_one :csat_survey_response, dependent: :destroy_async
  has_many :notifications, as: :primary_actor, dependent: :destroy_async

  after_create_commit :execute_after_create_commit_callbacks

  after_update_commit :dispatch_update_event
  # One registration: Rails keeps only the last of two commit callbacks naming the same method.
  after_commit :clear_whatsapp_missing_flag, on: [:create, :update], if: :proves_whatsapp_presence?
  after_commit :reindex_for_search, if: :should_index?, on: [:create, :update]

  def channel_token
    @token ||= inbox.channel.try(:page_access_token)
  end

  def push_event_data
    data = attributes.symbolize_keys.merge(
      created_at: created_at.to_i,
      message_type: message_type_before_type_cast,
      conversation_id: conversation&.display_id,
      conversation: conversation.present? ? conversation_push_event_data : nil
    )
    data[:echo_id] = echo_id if echo_id.present?
    data[:attachments] = attachments.map(&:push_event_data) if attachments.present?
    merge_sender_attributes(data)
  end

  def conversation_push_event_data
    {
      assignee_id: conversation.assignee_id,
      unread_count: conversation.unread_incoming_messages.count,
      last_activity_at: conversation.last_activity_at.to_i,
      contact_inbox: { source_id: conversation.contact_inbox.source_id }
    }
  end

  def merge_sender_attributes(data)
    data[:sender] = sender.push_event_data if sender && !sender.is_a?(AgentBot)
    data[:sender] = sender.push_event_data(inbox) if sender.is_a?(AgentBot)
    data
  end

  # The widget learns only that a contact sent the message, not the contact's stored details
  def widget_sender_data
    return { type: 'contact' } if sender.is_a?(Contact)

    sender.push_event_data
  end

  # The widget renders the whole message and forwards it to the host page, so the payload stays whole
  # and only a contact sender loses its stored details. Pass a built push_event_data to skip building it again.
  def widget_push_event_data(data = push_event_data)
    sender.is_a?(Contact) ? data.merge(sender: widget_sender_data) : data
  end

  def webhook_push_event_data
    push_event_data.merge(
      content: Messages::WebhookContentNormalizer.normalize(content),
      processed_message_content: Messages::WebhookContentNormalizer.normalize(processed_message_content)
    )
  end

  def webhook_data
    data = {
      account: account.webhook_data,
      additional_attributes: additional_attributes,
      content_attributes: content_attributes,
      content_type: content_type,
      content: webhook_content,
      conversation: conversation.webhook_data,
      created_at: created_at,
      id: id,
      inbox: inbox.webhook_data,
      message_type: message_type,
      private: private,
      sender: sender.try(:webhook_data),
      source_id: source_id
    }
    data[:attachments] = attachments.map(&:push_event_data) if attachments.present?
    data
  end

  # Method to get content with survey URL for outgoing channel delivery
  def outgoing_content
    MessageContentPresenter.new(self).outgoing_content
  end

  # Raw content with survey URL (no markdown rendering) for webhook consumers
  def webhook_content
    MessageContentPresenter.new(self).webhook_content
  end

  def email_notifiable_message?
    return false if private?
    return false if %w[outgoing template].exclude?(message_type)
    return false if template? && %w[input_csat text].exclude?(content_type)

    true
  end

  def forwarded?
    content_attributes['forwarded_message_id'].present?
  end

  def auto_reply_email?
    return false unless incoming_email? || inbox.email?

    content_attributes.dig(:email, :auto_reply) == true
  end

  def reaction?
    ActiveModel::Type::Boolean.new.cast(content_attributes['is_reaction']) == true
  end

  def deleted?
    ActiveModel::Type::Boolean.new.cast(content_attributes['deleted']) == true
  end

  # A removed reaction is a deleted row on purpose. WhatsApp allows one reaction per
  # (message, sender), so Chatwoot reuses the row and marks it deleted rather than
  # accumulating one per toggle, and the empty content it then carries is exactly the
  # payload that clears the reaction on the contact's phone. Every guard that keeps a
  # deleted message off the channel has to let this one through, or the emoji disappears
  # in Chatwoot and stays on the contact's phone forever.
  def removed_reaction?
    deleted? && content_attributes['is_reaction'].present?
  end

  # `content_attributes` is a single JSON column, so writing any of its store accessors from a stale
  # object rewrites the whole hash and drops flags another request set in the meantime — e.g. `deleted`,
  # written by the DELETE endpoint while an outgoing message was still in flight on the provider.
  # Reloads the row under FOR UPDATE before writing, which also serializes with those concurrent writers.
  def update_under_lock!(attributes)
    # `lock!` refuses to run on a record with unsaved changes. Flush what the caller left dirty — a
    # plain `update!` would have written it too — but never the stale `content_attributes` hash, since
    # writing it back is the very thing this method exists to prevent.
    restore_attributes(['content_attributes']) if content_attributes_changed?
    save! if changed?
    with_lock { update!(attributes) }
  end

  def valid_first_reply?
    return false unless human_response? && !private?
    return false if reaction?
    return false if conversation.first_reply_created_at.present?
    return false if conversation.messages.outgoing
                                .where.not(sender_type: BOT_SENDER_TYPES)
                                .where.not(private: true)
                                .not_forwarded
                                .where("(additional_attributes->'campaign_id') is null").count > 1

    true
  end

  def save_story_info(story_info)
    self.content_attributes = content_attributes.merge(
      {
        story_id: story_info['id'],
        story_sender: inbox.channel.instagram_id,
        story_url: story_info['url']
      }
    )
    save!
  end

  def send_update_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_UPDATED, Time.zone.now, message: self, performed_by: Current.executed_by,
                                                                            previous_changes: previous_changes)
  end

  def should_index?
    return false unless ChatwootApp.advanced_search_allowed?
    return false unless incoming? || outgoing?
    # For Chatwoot Cloud:
    #   - Enable indexing only if the account is paid.
    #   - The `advanced_search_indexing` feature flag is used only in the cloud.
    #
    # For Self-hosted:
    #   - Adding an extra feature flag here would cause confusion.
    #   - If the user has configured Elasticsearch, enabling `advanced_search`
    #     should automatically work without any additional flags.
    return false if ChatwootApp.chatwoot_cloud? && !account.feature_enabled?('advanced_search_indexing')

    true
  end

  def search_data
    Messages::SearchDataPresenter.new(self).search_data
  end

  # Returns message content suitable for LLM consumption
  # Falls back to audio transcription or attachment placeholder when content is nil
  def content_for_llm
    return content if content.present?

    audio_transcription = attachments
                          .where(file_type: :audio)
                          .filter_map { |att| att.meta&.dig('transcribed_text') }
                          .join(' ')
                          .presence
    return "[Voice Message] #{audio_transcription}" if audio_transcription.present?

    '[Attachment]' if attachments.any?
  end

  # An edit typed by an agent is written before the channel has taken it (`MessagesController#edit_content`
  # writes, then asks), and written back when the channel refuses. The optimistic write is not an edit
  # anybody made -- the contact still has the body they always had -- so the caller sets the flag above and
  # calls this once the channel has accepted.
  #
  # The write-back calls it too, and that is deliberate. When it restores a body an earlier edit had put
  # there, that body is the one the contact has, and the rules for it may never have run: the announcement
  # that named it found the refused body on the row and stood down (#660). Announcing it again costs
  # nothing, because the claim is taken on the body and a rule that already ran for it does not run twice.
  # A write-back that undoes a first edit announces nothing, and `edited_in_place?` is what says so: the
  # marker comes off in the same write.
  def announce_edit
    send_edited_event if edited_in_place?
  end

  # What the write-back after a refused edit has to say, which is two things and not one.
  #
  # The edit half is `announce_edit` above. The other half is the recovery: the announcement that named
  # the recovered body found the optimistic edit on the row and stood down (#661), and the refusal has
  # just put that body back with nobody having asked the arrival rules about it (#666). Only when the
  # body it restored is the recovered one -- a write-back that undoes a second edit restores the first
  # edit's body, and announcing that as recovered would have the rules answer about a body no recovery
  # ever carried, which is the defect #661 closed.
  #
  # Announcing again when the recovery was in fact evaluated costs nothing: `AutomationRuleListener`
  # only proceeds for a tracked placeholder arrival, and the run claim it takes is per message, so a
  # rule that already ran for this row does not run twice.
  def announce_restored_body
    announce_edit
    send_recovered_event if showing_recovered_body?
  end

  # When WhatsApp says the message happened, which for an imported one is long before the
  # row was written. WhatsApp stamps whole seconds, so this is the end of that second: a reply
  # stamped in the second a lookup started may have been sent after it, and a reply proves the
  # number either way, so the tie goes to presence.
  def whatsapp_sent_at
    seconds = content_attributes&.dig('external_created_at').presence
    (seconds ? Time.zone.at(seconds.to_i) : created_at).change(usec: 999_999)
  end

  private

  def prevent_message_flooding
    # Added this to cover the validation specs in messages
    # We can revisit and see if we can remove this later
    return if conversation.blank?
    return if skip_message_flooding_validation

    # there are cases where automations can result in message loops, we need to prevent such cases.
    if conversation.messages.where('created_at >= ?', 1.minute.ago).count >= Limits.conversation_message_per_minute_limit
      Rails.logger.error "Too many message: Account Id - #{account_id} : Conversation id - #{conversation_id}"
      errors.add(:base, 'Too many messages')
    end
  end

  def ensure_processed_message_content
    text_content_quoted = content_attributes.dig(:email, :text_content, :quoted)
    html_content_quoted = content_attributes.dig(:email, :html_content, :quoted)

    message_content = text_content_quoted || html_content_quoted || content
    self.processed_message_content = message_content&.truncate(150_000)
  end

  # fetch the in_reply_to message and set the external id
  def ensure_in_reply_to
    in_reply_to = content_attributes[:in_reply_to]
    in_reply_to_external_id = content_attributes[:in_reply_to_external_id]

    Messages::InReplyToMessageBuilder.new(
      message: self,
      in_reply_to: in_reply_to,
      in_reply_to_external_id: in_reply_to_external_id
    ).perform
  end

  def ensure_content_type
    self.content_type ||= Message.content_types[:text]
  end

  def execute_after_create_commit_callbacks
    # rails issue with order of active record callbacks being executed https://github.com/rails/rails/issues/20911
    reopen_conversation
    mark_pending_conversation_as_open_for_human_response
    set_conversation_activity
    dispatch_create_events
    send_reply
    execute_message_template_hooks
    update_contact_activity
  end

  # Anything the contact sends, and any receipt from their phone, proves the number has
  # WhatsApp, so a "no WhatsApp" flag left by an earlier lookup stops warning, as long as the
  # evidence is newer than that lookup. On every thread of the contact in this inbox, since
  # the flag is about the phone and a contact can hold more than one (phone and LID). One read
  # that finds nothing in the usual case.
  def clear_whatsapp_missing_flag
    return unless inbox.channel_type == 'Channel::Whatsapp'

    # A lookup still waiting on the provider has no flag here to clear, so the receipt is
    # also left where that lookup will read it before writing its "no".
    ContactInbox.remember_whatsapp_receipt(inbox_id, conversation.contact_id, created_at) if outgoing?
    flagged = ContactInbox.where(inbox_id: inbox_id, contact_id: conversation.contact_id)
                          .where(whatsapp_missing_checked_at: ...whatsapp_evidence_at)
    ids = flagged.pluck(:id)
    return if ids.empty?

    flagged.where(id: ids).update_all(whatsapp_missing_checked_at: nil) # rubocop:disable Rails/SkipsModelValidations
    # update_all skips the contact inbox's own commit callback, so the rare clear tells the
    # dashboard itself. This conversation's loaded association still holds the old date, and
    # this message's own callbacks broadcast it again right after (reopening it,
    # waiting_since), so it is reloaded first.
    conversation.reload_contact_inbox
    ContactInbox.where(id: ids).find_each(&:broadcast_whatsapp_missing_change)
  end

  # An incoming message counts when it is written. An outgoing one counts only when a
  # receipt moves it to delivered or read as it happens: an echo of a send from the paired
  # phone is born delivered without any receipt, and an import replays receipts from the past.
  def proves_whatsapp_presence?
    return incoming? if previously_new_record?

    outgoing? && saved_change_to_status? && (delivered? || read?) && !Import::SilentWrite.on?
  end

  # A message is as old as WhatsApp says it is, which for an imported one is long before the
  # row was written. A receipt is as old as the message it answers: only one sent after the
  # lookup surely went to the phone that lookup asked about, since a phone change wipes the
  # flag and a send to a number with no account never gets a receipt. A late receipt for an
  # older message is left to the recheck.
  def whatsapp_evidence_at = incoming? ? whatsapp_sent_at : created_at

  def update_contact_activity
    sender.update!(last_activity_at: DateTime.now) if sender.is_a?(Contact)
  end

  def update_waiting_since
    clear_waiting_since_on_outgoing_response if conversation.waiting_since.present? && !private
    set_waiting_since_on_incoming_message
  end

  def clear_waiting_since_on_outgoing_response
    if human_response?
      Rails.configuration.dispatcher.dispatch(
        REPLY_CREATED, Time.zone.now, waiting_since: conversation.waiting_since, message: self
      )
      conversation.update!(waiting_since: nil)
      return
    end

    # Bot responses also clear waiting_since (simpler than checking on next customer message)
    conversation.update!(waiting_since: nil) if bot_response? && !preserve_waiting_since
  end

  def set_waiting_since_on_incoming_message
    # Reactions are annotations, not a new turn awaiting a reply; treating an
    # incoming reaction as one would push an already-attended conversation back
    # into the unattended queue (and leave it stuck there, since removals don't
    # create a Message that could clear it). Mirrors the reaction guard on the
    # outgoing side (`human_response?`).
    return if reaction?

    # Set waiting_since when customer sends a message (if currently blank)
    conversation.update!(waiting_since: created_at) if incoming? && conversation.waiting_since.blank?
  end

  def human_response?
    # Reactions are not substantive replies; treating them as one would
    # clear `waiting_since` / dispatch REPLY_CREATED on every emoji toggle
    # and skew SLA timers for conversations the agent has not actually
    # answered yet.
    return false if reaction?

    # if the sender is not a user, it's not a human response
    # if automation rule id is present, it's not a human response
    # if campaign id is present, it's not a human response
    # external echo messages are responses sent from the native app (WhatsApp Business, Instagram)
    # forwarded emails go to a third party, not to the contact
    outgoing? &&
      !forwarded? &&
      content_attributes['automation_rule_id'].blank? &&
      additional_attributes['campaign_id'].blank? &&
      (sender.is_a?(User) || content_attributes['external_echo'].present?)
  end

  def bot_response?
    # Check if this is a response from AgentBot or Captain::Assistant
    outgoing? && sender_type.in?(BOT_SENDER_TYPES)
  end

  def dispatch_create_events
    Rails.configuration.dispatcher.dispatch(MESSAGE_CREATED, Time.zone.now, message: self, performed_by: Current.executed_by)

    if valid_first_reply?
      Rails.configuration.dispatcher.dispatch(FIRST_REPLY_CREATED, Time.zone.now, message: self, performed_by: Current.executed_by)
      conversation.update!(first_reply_created_at: created_at, waiting_since: nil)
    else
      update_waiting_since
    end
  end

  def dispatch_update_event
    # ref: https://github.com/rails/rails/issues/44500
    # we want to skip the update event if the message is not updated
    return if previous_changes.blank?

    send_update_event
    send_edited_event if edited_in_place? && !defer_edit_announcement
  end

  # The body changed and the row says an edit is what changed it. Both halves are load-bearing.
  #
  # `content` and not `content_attributes`: a delayed recovery landing on a row an edit already settled
  # writes everything around the body and leaves the body alone (`MessageWriter#reconcile_in_place`),
  # and that row still carries `is_edited` from the earlier edit, so the marker alone would announce an
  # edit nobody made. And `is_edited` and not the content change alone, because the send failure of an
  # edit writes the original body back with the marker off (`MessagesController#edit_content`): that is
  # an undo, and announcing it would run the rules on a body the contact never saw.
  #
  # Nothing here has to deduplicate a redelivery. The providers resend events, and an edit applied a
  # second time writes the same body: Rails sees no change, `previous_changes` comes back empty and this
  # callback returns above. Measured, not assumed.
  def edited_in_place?
    previous_changes.key?('content') && is_edited
  end

  # The row is showing the body a recovery brought, rather than anything written over it since. Absent on
  # every row no recovery ever filled in, which is what keeps this quiet for an ordinary message.
  def showing_recovered_body?
    digest = content_attributes.to_h[RECOVERED_BODY]

    digest.present? && digest == Digest::SHA256.hexdigest(content.to_s)
  end

  # Named, like every other announcement that speaks of a body, so the listener can tell whether the row
  # still shows what this is about by the time the work runs.
  def send_recovered_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_RECOVERED, Time.zone.now, message: self, content: content)
  end

  # `content` is the body this announcement speaks of, and the listener only evaluates the rules while the
  # row is still showing it: the work runs long after the dispatch, and a second edit committing in
  # between would otherwise have the rules answer about a body this announcement is not about (#660).
  def send_edited_event
    Rails.configuration.dispatcher.dispatch(MESSAGE_EDITED, Time.zone.now, message: self, content: content,
                                                                           performed_by: Current.executed_by,
                                                                           previous_changes: previous_changes)
  end

  def send_reply
    # FIXME: Giving it few seconds for the attachment to be uploaded to the service
    # active storage attaches the file only after commit
    attachments.blank? ? ::SendReplyJob.perform_later(id) : ::SendReplyJob.set(wait: 2.seconds).perform_later(id)
  end

  def reopen_conversation
    return if conversation.muted?
    return unless incoming?
    return if reaction?
    return unless conversation.snoozed? || conversation.resolved?

    conversation.check_assignee_team_on_reopen
    conversation.snoozed? ? conversation.open! : reopen_resolved_conversation
  end

  def mark_pending_conversation_as_open_for_human_response
    return unless captain_pending_conversation?
    return unless human_response?
    return if private?
    return if reaction?

    conversation.open!
  end

  def captain_pending_conversation?
    false
  end

  def reopen_resolved_conversation
    # mark resolved bot conversation as pending to be reopened by bot processor service
    if conversation.inbox.active_bot?
      conversation.hand_reopen_to_agent_bot
      conversation.pending!
    elsif conversation.inbox.api?
      Current.executed_by = sender if reopened_by_contact?
      conversation.open!
    else
      conversation.open!
    end
  end

  def reopened_by_contact?
    incoming? && !private? && Current.user.class != sender.class && sender.instance_of?(Contact)
  end

  def execute_message_template_hooks
    ::MessageTemplates::HookExecutionService.new(message: self).perform
  end

  def validate_attachments_limit(_attachment)
    errors.add(:attachments, message: 'exceeded maximum allowed') if attachments.size >= NUMBER_OF_PERMITTED_ATTACHMENTS
  end

  def set_conversation_activity
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_columns(last_activity_at: created_at, updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def reindex_for_search
    return unless respond_to?(:reindex)

    reindex(mode: :async)
  end
end

Message.prepend_mod_with('Message')
Message.include_mod_with('Concerns::Message')
