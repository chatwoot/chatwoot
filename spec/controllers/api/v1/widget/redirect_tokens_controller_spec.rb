require 'rails_helper'

RSpec.describe 'Api::V1::Widget::RedirectTokensController', type: :request do
  let(:account) { create(:account) }
  let(:web_widget) { create(:channel_widget, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: web_widget.inbox) }
  let(:auth_payload) { { source_id: contact_inbox.source_id, inbox_id: web_widget.inbox.id } }
  let(:token) { Widget::TokenService.new(payload: auth_payload).generate_token }

  describe 'POST /api/v1/widget/redirect_token' do
    context 'with an invalid redirect token' do
      it 'returns not found' do
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: 'does-not-exist' },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('invalid_token')
      end
    end

    context 'with a valid redirect token carrying a message' do
      let(:redirect_token) do
        Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'message' => 'Hello' })
      end

      it 'identifies the contact, verifies the inbox and injects the message' do
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body['conversation_id']).to be_present
        # The existing session keeps its auth token when the identity does not change.
        expect(body['widget_auth_token']).to be_nil

        expect(contact.reload.identifier).to eq('user-42')
        expect(contact_inbox.reload.hmac_verified).to be(true)

        conversation = contact.conversations.last
        expect(conversation.messages.where(message_type: :incoming).last.content).to eq('Hello')
      end

      it 'consumes the token so it cannot be reused' do
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(Widget::RedirectToken.consume(redirect_token)).to be_nil
      end
    end

    context 'when the session contact is already identified with a different identifier' do
      let(:contact) { create(:contact, account: account, identifier: 'someone-else') }

      it 'issues a fresh widget auth token for the redirected identity' do
        redirect_token = Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42' })

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['widget_auth_token']).to be_present
      end
    end

    context 'when the token was minted for a different inbox' do
      it 'rejects the token as invalid' do
        other_widget = create(:channel_widget, account: account)
        foreign_token = Widget::RedirectToken.generate({ 'inbox_id' => other_widget.inbox.id, 'identifier' => 'user-42' })

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: foreign_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('invalid_token')
      end
    end

    # fazer-ai/agents#222: the two conversations of one redirect episode could not be paired from
    # anything this side stores. The origin rides in the token because the mint is the only moment
    # both halves are known together.
    context 'when the token carries the origin conversation' do
      it 'records it on the widget conversation, as the display_id' do
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'message' => 'Hello', 'origin_display_id' => 77 }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.conversations.last.redirect_origin_display_id).to eq(77)
      end

      it 'ships it to the consumers on push_data, and leaves it out when there is none' do
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'message' => 'Hello', 'origin_display_id' => 77 }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        redirected = contact.reload.conversations.last
        expect(redirected.push_event_data[:redirect_origin_display_id]).to eq(77)
        # A conversation outside a redirect episode carries the key with nil — NOT absent. Absent is
        # reserved for a Chatwoot that does not speak about pairings at all, so a consumer can tell
        # "there is no pairing" from "this instance said nothing", and can therefore mirror a CLEAR.
        unpaired = create(:conversation, account: account).push_event_data
        expect(unpaired).to have_key(:redirect_origin_display_id)
        expect(unpaired[:redirect_origin_display_id]).to be_nil
      end

      # The consumer acts on the FIRST event it receives, which is the cloned message. AgentBotListener
      # is on the SYNC dispatcher, so that payload is built inside Message.create!, and the pairing has
      # to be on the row before the message exists. The conversation_updated that follows is a second
      # witness, not a substitute: a consumer that answered the message already used the old pairing.
      it 'is already on the conversation the first webhook payload carries' do
        agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://bot.test/hook')
        create(:agent_bot_inbox, inbox: web_widget.inbox, agent_bot: agent_bot, account: account)
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'message' => 'Hello', 'origin_display_id' => 77 }
        )

        payloads = []
        allow(AgentBots::WebhookJob).to receive(:perform_later) { |_url, payload, *| payloads << payload }

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        message_created = payloads.find { |pl| pl[:event] == 'message_created' }
        expect(message_created).to be_present
        expect(message_created[:conversation][:redirect_origin_display_id]).to eq(77)
      end

      # The four event shapes this endpoint can produce, pinned together so no reordering can change
      # one without showing up here. What every row has in common is the point: the origin a consumer
      # reads is the NEW one, on every event either path emits.
      it 'names the new origin on every event it emits, whichever path ran' do
        agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://bot.test/hook')
        create(:agent_bot_inbox, inbox: web_widget.inbox, agent_bot: agent_bot, account: account)

        redirect = lambda do |payload|
          seen = []
          allow(AgentBots::WebhookJob).to receive(:perform_later) { |_url, pl, *| seen << pl }
          post '/api/v1/widget/redirect_token',
               params: { website_token: web_widget.website_token,
                         token: Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id,
                                                                 'identifier' => 'user-42' }.merge(payload)) },
               headers: { 'X-Auth-Token' => token }, as: :json
          # Every payload names the pairing, template messages included; the widget's email-collect
          # templates ride along on the first inbound and say nothing about the episode, so the
          # sequence below is the customer-visible one.
          expect(seen.map { |pl| pl[:redirect_origin_display_id] || pl.dig(:conversation, :redirect_origin_display_id) }.uniq)
            .to eq(seen.empty? ? [] : [payload['origin_display_id']].compact.presence || [nil])
          seen.reject { |pl| pl[:message_type] == 'template' }.map do |pl|
            [pl[:event], pl[:redirect_origin_display_id] || pl.dig(:conversation, :redirect_origin_display_id)]
          end
        end

        # A first redirect creates the conversation, so its pairing rides on the creation itself.
        redirect.call('origin_display_id' => 77)

        # Origin changes, cloned message: the update states it, and the message a consumer acts on
        # already carries it.
        expect(redirect.call('origin_display_id' => 91, 'message' => 'oi'))
          .to eq([%w[conversation_updated] << 91, %w[message_created] << 91].map(&:flatten))

        # Origin changes, no message: the update is the only witness there is, which is why the column
        # is in list_of_keys at all.
        expect(redirect.call('origin_display_id' => 77)).to eq([['conversation_updated', 77]])

        # Origin unchanged, cloned message: nothing to state, and the message still names it.
        expect(redirect.call('origin_display_id' => 77, 'message' => 'de novo'))
          .to eq([['message_created', 77]])

        # Origin unchanged, no message: no row changed and no message exists, so there is nothing for
        # an event to say. A repeated link from one WhatsApp conversation lands here.
        expect(redirect.call('origin_display_id' => 77)).to eq([])

        # No origin at all: the pairing is CLEARED, and the clear is announced like any other change.
        # The key is then absent from the payload, the same shape a conversation outside an episode has.
        expect(redirect.call({})).to eq([['conversation_updated', nil]])

        # ...and once it is gone, a second origin-less token has nothing left to clear.
        expect(redirect.call({})).to eq([])
      end

      # The message-less resume path (cloneWaMessage off, or a media-only WhatsApp message) writes the
      # pairing onto a conversation that ALREADY exists, so neither a creation event nor a cloned
      # message carries it. Unless that write is observable on its own, a consumer keeps the previous
      # episode's origin and acts on the wrong WhatsApp conversation (fazer-ai/agents#355, round 1).
      it 'emits an event carrying the new origin when a message-less token re-enters a conversation' do
        agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://bot.test/hook')
        create(:agent_bot_inbox, inbox: web_widget.inbox, agent_bot: agent_bot, account: account)

        first = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: first },
             headers: { 'X-Auth-Token' => token }, as: :json

        payloads = []
        allow(AgentBots::WebhookJob).to receive(:perform_later) { |_url, payload, *| payloads << payload }

        second = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 91 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: second },
             headers: { 'X-Auth-Token' => token }, as: :json

        updated = payloads.find { |pl| pl[:event] == 'conversation_updated' }
        expect(updated).to be_present
        expect(updated[:redirect_origin_display_id]).to eq(91)
      end

      it 'takes the newest origin on re-entry, and a token without one clears it' do
        first = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: first },
             headers: { 'X-Auth-Token' => token }, as: :json

        second = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 91 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: second },
             headers: { 'X-Auth-Token' => token }, as: :json
        expect(contact.reload.conversations.last.redirect_origin_display_id).to eq(91)

        # Consuming a token is the ONE event that sets the pairing, so a token that names no origin
        # leaves the previous one with nothing behind it: the lead came back through a link this
        # instance cannot attribute. Keeping it would hand a consumer that MESSAGES and RESOLVES the
        # named conversation full confidence in a previous episode's answer; clearing it sends that
        # consumer to whatever it does when it has no answer, which is a decision it makes knowingly.
        third = Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42' })
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: third },
             headers: { 'X-Auth-Token' => token }, as: :json
        expect(contact.reload.conversations.last.redirect_origin_display_id).to be_nil
      end

      # Review round 7 of #418. "Last write wins" is the contract this endpoint states, and the guard
      # below it was comparing against an ActiveRecord instance loaded before the token was even
      # resolved. Two links clicked into the same widget conversation at once, and the request that
      # finishes LAST can find its own origin already in memory, skip both the write and the event,
      # and leave the other request's origin standing.
      #
      # The rendezvous is the row moving between the load and the guard, which is exactly what a
      # concurrent resume does to it. `update_all` is the right tool: it changes the row without
      # touching the instance the controller is holding.
      it 'writes the origin its own token names even if the row moved under it' do
        first = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: first },
             headers: { 'X-Auth-Token' => token }, as: :json
        conversation = contact.reload.conversations.last
        expect(conversation.redirect_origin_display_id).to eq(77)

        # any_instance because a request spec never holds the controller, and the rendezvous has to sit
        # between the conversation LOAD and the lock that reloads it — the window a concurrent resume
        # actually lands in. update_all for the same reason it is the defect: it moves the ROW without
        # telling the instance the controller is holding.
        # rubocop:disable RSpec/AnyInstance, Rails/SkipsModelValidations
        allow_any_instance_of(Api::V1::Widget::RedirectTokensController)
          .to receive(:with_episode_lock).and_wrap_original do |original, *args, &block|
          Conversation.where(id: conversation.id).update_all(redirect_origin_display_id: 91)
          original.call(*args, &block)
        end
        # rubocop:enable RSpec/AnyInstance, Rails/SkipsModelValidations

        again = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: again },
             headers: { 'X-Auth-Token' => token }, as: :json

        # This request's token named 77 and it ran last, so 77 is the pairing. Without the lock the
        # stale instance answers "already 77" and 91 survives.
        expect(conversation.reload.redirect_origin_display_id).to eq(77)
      end

      # The create path's event shape, pinned because a comment in this controller used to imply more
      # than it should. The row carries the pairing from birth, but AgentBotListener has no
      # conversation_created handler, so nothing reaches a bot at creation. Nothing is lost by it —
      # the pairing is on the row, so the first event a bot DOES receive carries it — and widening
      # that is a change to the agent-bot contract for every inbox, not this endpoint's to make.
      it 'delivers no bot event on creation, and names the origin on the first one that follows' do
        agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://bot.test/hook')
        create(:agent_bot_inbox, inbox: web_widget.inbox, agent_bot: agent_bot, account: account)
        payloads = []
        allow(AgentBots::WebhookJob).to receive(:perform_later) { |_url, pl, *| payloads << pl }

        creating = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: creating },
             headers: { 'X-Auth-Token' => token }, as: :json

        conversation = contact.reload.conversations.last
        expect(conversation.redirect_origin_display_id).to eq(77)
        expect(payloads).to be_empty

        # The lead writes. That message is the first thing the bot hears about this conversation, and
        # it names the pairing the creation recorded.
        create(:message, account: account, inbox: web_widget.inbox, conversation: conversation,
                         sender: contact, message_type: :incoming, content: 'oi')
        first = payloads.find { |pl| pl[:event] == 'message_created' }
        expect(first).to be_present
        expect(first[:conversation][:redirect_origin_display_id]).to eq(77)
      end

      # Review round 9 of #418. The born-here skip was reasoned from "nothing could have raced a row
      # that did not exist", and that is only true until the INSERT commits. After it, a second
      # resume can load the same conversation and move its origin, and this request would then create
      # its message from a cached origin the row no longer holds — the same incoherence the lock
      # exists to prevent, on the one path that skipped the lock.
      #
      # The skip was never about the race anyway: it was about `with_lock` refusing to lock a record
      # with an unpersisted `display_id`. A reload clears that, so the lock can be taken here too.
      it 'locks a conversation it created itself' do
        conversation = nil
        # rubocop:disable RSpec/AnyInstance, Rails/SkipsModelValidations
        allow_any_instance_of(Api::V1::Widget::RedirectTokensController)
          .to receive(:with_episode_lock).and_wrap_original do |original, *args, &block|
          conversation = contact.reload.conversations.last
          Conversation.where(id: conversation.id).update_all(redirect_origin_display_id: 91)
          original.call(*args, &block)
        end
        # rubocop:enable RSpec/AnyInstance, Rails/SkipsModelValidations

        t = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77, 'message' => 'oi' }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: t },
             headers: { 'X-Auth-Token' => token }, as: :json

        expect(response).to have_http_status(:success)
        # This request's token named 77 and it is the one that ran, so the row is 77 — and the message
        # it created belongs to the same episode.
        expect(conversation.reload.redirect_origin_display_id).to eq(77)
        expect(conversation.messages.where(message_type: :incoming).last.content).to eq('oi')
      end

      # And the clear is announced, on the same terms as a change: it moves the column, so it emits
      # its own conversation_updated. A consumer that only ever hears about origins it can act on
      # would keep acting on the one this token just invalidated.
      it 'announces the clear, and stops shipping the key' do
        agent_bot = create(:agent_bot, account: account, outgoing_url: 'https://bot.test/hook')
        create(:agent_bot_inbox, inbox: web_widget.inbox, agent_bot: agent_bot, account: account)
        first = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42', 'origin_display_id' => 77 }
        )
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: first },
             headers: { 'X-Auth-Token' => token }, as: :json

        payloads = []
        allow(AgentBots::WebhookJob).to receive(:perform_later) { |_url, pl, *| payloads << pl }

        second = Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id, 'identifier' => 'user-42' })
        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: second },
             headers: { 'X-Auth-Token' => token }, as: :json

        updated = payloads.find { |pl| pl[:event] == 'conversation_updated' }
        expect(updated).to be_present
        # Stated as nil, so a consumer can mirror the clear instead of keeping what it had.
        expect(updated).to have_key(:redirect_origin_display_id)
        expect(updated[:redirect_origin_display_id]).to be_nil
      end
    end

    context 'when the token carries no identifier and the session contact is already identified' do
      let(:contact) { create(:contact, account: account, identifier: 'existing-id') }

      it 'keeps the existing identified session' do
        redirect_token = Widget::RedirectToken.generate({ 'inbox_id' => web_widget.inbox.id, 'message' => 'Hello again' })

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['widget_auth_token']).to be_nil
        expect(contact.reload.identifier).to eq('existing-id')
        expect(contact.contact_inboxes.count).to eq(1)
      end
    end

    # THE ORPHAN THIS ENDPOINT USED TO CREATE (fazer-ai/agents#286, split out of #269).
    #
    # `ContactIdentifyAction` decides by the identifier: it MERGES the visitor onto whoever holds the
    # value and ASSIGNS the value when nobody does. For a redirect minted FOR a contact, assigning is
    # wrong — the value belongs to that contact by construction, so a browser session that merely
    # presented a token walks away holding it, and the lead ends up with two contacts, the second
    # squatting the identifier every later redirect for it needs.
    #
    # Reproduced against this controller before the fix: with nobody holding the identifier, a resolve
    # left 2 contacts, the lead carrying none and the visitor holding the lead's `fzwa:` value. That is
    # the production state #269 measured and #272 could not reproduce.
    context 'when the token names the contact it was minted for' do
      let(:lead) { create(:contact, account: account, identifier: 'fzwa:77') }

      it 'unifies the visitor onto it when the identifier is where it should be' do
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77', 'identified_contact_id' => lead.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Contact.exists?(contact.id)).to be(false)
        expect(account.contacts.count).to eq(1)
      end

      it 'unifies onto it even when the identifier is no longer there, and restores the value' do
        lead.update!(identifier: nil)
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77', 'identified_contact_id' => lead.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Contact.exists?(contact.id)).to be(false)
        expect(account.contacts.count).to eq(1)
        expect(lead.reload.identifier).to eq('fzwa:77')
      end

      # Identifiers are mutable through the contacts API and the ingestion services, and a link from
      # yesterday is not evidence about who this contact says it is today.
      it 'never overwrites an identifier the contact has since been given' do
        lead.update!(identifier: 'crm-7788')
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77', 'identified_contact_id' => lead.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(lead.reload.identifier).to eq('crm-7788')
        expect(Contact.exists?(contact.id)).to be(false)
      end

      it 'unifies without raising when a third contact took the value meanwhile' do
        lead.update!(identifier: nil)
        squatter = create(:contact, account: account, identifier: 'fzwa:77')
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77', 'identified_contact_id' => lead.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Contact.exists?(contact.id)).to be(false)
        # WHERE the visitor landed is the whole assertion: identifying by the identifier would have
        # merged it onto the squatter, which holds the value and is not this lead.
        expect(contact_inbox.reload.contact_id).to eq(lead.id)
        expect(lead.reload.identifier).to be_nil
        expect(squatter.reload.identifier).to eq('fzwa:77')
      end

      # A SESSION ALREADY LOGGED IN AS SOMEBODY ELSE IS NOT THE MERGEE.
      #
      # The fresh-session guard above keys on the identifier, so a token that names a contact and
      # carries no identifier walked straight past it: the browser's own identified customer became
      # the mergee, and the merge moved ITS conversations, inboxes and messages onto the named target
      # and destroyed it. Clicking a link meant for someone else would take a customer's history with
      # it.
      it 'does not swallow a customer who is already identified as somebody else' do
        stranger = create(:contact, account: account, identifier: 'crm-stranger')
        stranger_inbox = create(:contact_inbox, contact: stranger, inbox: web_widget.inbox)
        stranger_token = Widget::TokenService.new(
          payload: { source_id: stranger_inbox.source_id, inbox_id: web_widget.inbox.id }
        ).generate_token
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identified_contact_id' => lead.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => stranger_token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Contact.exists?(stranger.id)).to be(true)
        expect(stranger.reload.identifier).to eq('crm-stranger')
      end

      # The lead clicking its own link again, in the browser it already crossed on. There is no other
      # identity to protect here, so the session is kept rather than replaced: without the id
      # comparison this branch would mint a throwaway contact and a fresh auth token on every click,
      # and then merge it straight back.
      it 'keeps the session when it is already the named contact' do
        contact.update!(identifier: 'fzwa:55')
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identified_contact_id' => contact.id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['widget_auth_token']).to be_nil
        expect(Contact.exists?(contact.id)).to be(true)
        expect(contact_inbox.reload.contact_id).to eq(contact.id)
      end

      # THE SAME QUESTION, ASKED OF EVERY FIELD THAT ANSWERS IT.
      #
      # `ContactIdentifyAction` merges on three attributes — identifier, email and phone_number — so
      # those three are what \"this browser is already somebody\" means. Asking only about the
      # identifier left a pre-chat contact (email or phone, no identifier) reading as anonymous, and
      # an anonymous session is the one thing this branch may consume: it became the mergee and its
      # history moved onto a contact it has nothing to do with.
      %i[email phone_number].each do |field|
        it "does not swallow a customer established by #{field} alone" do
          value = field == :email ? 'someone@example.com' : '+553299887766'
          stranger = create(:contact, :account => account, field => value)
          stranger_inbox = create(:contact_inbox, contact: stranger, inbox: web_widget.inbox)
          stranger_token = Widget::TokenService.new(
            payload: { source_id: stranger_inbox.source_id, inbox_id: web_widget.inbox.id }
          ).generate_token
          redirect_token = Widget::RedirectToken.generate(
            { 'inbox_id' => web_widget.inbox.id, 'identified_contact_id' => lead.id }
          )

          post '/api/v1/widget/redirect_token',
               params: { website_token: web_widget.website_token, token: redirect_token },
               headers: { 'X-Auth-Token' => stranger_token },
               as: :json

          expect(response).to have_http_status(:success)
          expect(Contact.exists?(stranger.id)).to be(true)
          expect(stranger.reload.public_send(field)).to eq(value)
        end
      end

      # The rejected value must not ride out on the cloned message either: `Message.create!` builds
      # its payload from this very object, and the SYNC dispatcher hands it to agent bots and
      # websockets before anything reloads.
      it 'does not announce an identifier the database refused' do
        lead.update!(identifier: nil)
        create(:contact, account: account, identifier: 'fzwa:77')
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77',
            'identified_contact_id' => lead.id, 'message' => 'Hello' }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        conversation = Conversation.find_by(display_id: response.parsed_body['conversation_id'])
        cloned = conversation.messages.find_by(content: 'Hello')
        expect(cloned.sender.identifier).to be_nil
      end

      it 'identifies nobody when the named contact is gone' do
        gone_id = lead.id
        lead.destroy!
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'fzwa:77', 'identified_contact_id' => gone_id }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.identifier).to be_nil
      end
    end

    # The older, looser contract, and it is the reason the field is optional: a deep link minted for
    # an identity this account has never seen still creates it.
    context 'when the token names no contact' do
      it 'still establishes a brand-new identity on the visitor' do
        contact_inbox
        redirect_token = Widget::RedirectToken.generate(
          { 'inbox_id' => web_widget.inbox.id, 'identifier' => 'crm-user-42' }
        )

        post '/api/v1/widget/redirect_token',
             params: { website_token: web_widget.website_token, token: redirect_token },
             headers: { 'X-Auth-Token' => token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(contact.reload.identifier).to eq('crm-user-42')
      end
    end
  end
end
