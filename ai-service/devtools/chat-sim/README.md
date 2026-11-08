# Chat simulator and hard-case runner (local only)

Two tools for trying the support bot end to end on this Mac, the way a
customer meets it on Facebook Messenger: page → local Chatwoot → ai-service →
reply. Part of issue #1.

## One-time setup

1. Local Chatwoot and ai-service running (`local/docker-compose.yml`).
2. An **API inbox** named `Messenger test` in local Chatwoot with the agent
   bot attached. Create it once (Rails console in the `rails` container):

   ```ruby
   a = Account.find(1)
   ib = a.inboxes.create!(name: "Messenger test", channel: Channel::Api.create!(account: a))
   AgentBotInbox.create!(inbox: ib, agent_bot: AgentBot.first, account: a)
   ```

3. In `local/ai-service.env`, set `CHATWOOT_PUBLIC_URL=http://localhost:3000`.
   Without it the bot cannot download photos, stickers or voice notes, because
   Chatwoot writes `localhost:3000` into file links while the bot reaches it as
   `rails:3000`.
4. For replies like production's, copy the business profile and switch on
   voice, images and stickers on `/admin` (they are off by default).

## Chat simulator

```bash
devtools/chat-sim/run.sh          # then open http://127.0.0.1:8099/
```

`run.sh` finds the inbox, writes its public identifier to `config.js`
(gitignored) and serves the page. What it does like Messenger:

- Enter sends at once, so quick messages arrive one by one.
- 👍 and stickers go as images, the way Facebook delivers them.
- 🎤 records a voice note; ＋ sends photos, audio, video or PDF.
- The header chip shows who is answering: Bot, Staff (handed off) or Resolved.
- **New customer** starts a fresh contact; **Open in Chatwoot** shows the
  staff view of the same chat.

Not like Messenger: the typing dots are the page's own guess while it waits,
and there is no 24-hour reply window.

## Hard-case runner

```bash
python3 -I devtools/chat-sim/hardcases.py devtools/chat-sim/hardcases.json out.json \
  --media <folder with voice.m4a, sticker.png, clip.mp4, quote.pdf, slip.png, ...>
```

Each case in `hardcases.json` is a new customer. Steps: `say`, `burst`
(several quick messages), `file`, `staff_say`, `staff_status`, `restart_bot`,
`sleep`. The output holds every message (private notes included), the
conversation status, labels and custom attributes, plus what a good reply
looks like (`expect`) for a person to grade. It reads the inbox identifier and
a staff API token from the **local** Chatwoot database and never prints them.
Cases that restart the bot run alone after the others.
