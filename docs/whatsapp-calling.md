# WhatsApp Calling in Chatwoot

WhatsApp Calling lets agents receive and make voice calls directly from the Chatwoot dashboard using the WhatsApp Cloud API. Calls are browser-based (WebRTC) — no phone hardware or Twilio required.

> **Enterprise only.** Gated behind the `whatsapp_call` feature flag.

---

## Table of Contents

1. [How WhatsApp Calling Works (The Big Picture)](#1-how-whatsapp-calling-works-the-big-picture)
2. [Setup Guide](#2-setup-guide)
3. [Product Walkthrough](#3-product-walkthrough)
4. [Technical Architecture](#4-technical-architecture)
5. [Call Flows (Step by Step)](#5-call-flows-step-by-step)
6. [Call Recording & Transcription](#6-call-recording--transcription)
7. [Data Model](#7-data-model)
8. [API Reference](#8-api-reference)
9. [WebSocket Events](#9-websocket-events)
10. [Key Files](#10-key-files)
11. [Challenges & Design Decisions](#11-challenges--design-decisions)
12. [Extending the Feature](#12-extending-the-feature)

---

## 1. How WhatsApp Calling Works (The Big Picture)

Before diving into code, here's the mental model for the entire feature.

### Three players, two communication channels

```
 ┌─────────────────────────────────────────────────────────────────┐
 │                                                                 │
 │   1. SIGNALING (who's calling whom, accept/reject, hang up)    │
 │      Travels through: Meta API <-> Chatwoot Backend <-> Browser │
 │                                                                 │
 │   2. AUDIO (the actual voice data)                              │
 │      Travels through: Meta Servers <-----------> Browser        │
 │      (Chatwoot backend is NOT in this path)                     │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
```

Think of it like a phone operator (signaling) connecting two people (audio). The operator sets up the call but doesn't listen in — the audio flows directly between the two parties.

```
┌──────────────┐                                      ┌──────────────────┐
│   WhatsApp   │         Signaling (REST/Webhooks)     │   Chatwoot       │
│   Contact    │◄─────────────────────────────────────►│   Backend        │
│              │                                       │   (Rails)        │
└──────┬───────┘                                       └────────┬─────────┘
       │                                                        │
       │                                              WebSocket │ (ActionCable)
       │                                                        │
       │         ┌────────────────────────┐            ┌────────▼─────────┐
       │         │   Meta Media Servers   │            │   Agent's        │
       │         │                        │            │   Browser        │
       └────────►│  (routes the audio     │◄══════════►│   (Vue + WebRTC) │
                 │   between endpoints)   │  Audio     │                  │
                 └────────────────────────┘  (SRTP)    └──────────────────┘
```

**Why does Chatwoot's backend not touch the audio?**

The audio is a peer-to-peer WebRTC connection between the agent's browser and Meta's media servers. This is intentional — it reduces latency, avoids the need for media proxies, and is how Meta designed their calling API. The browser has direct access to both audio tracks (local mic + remote caller), which is what makes client-side call recording possible.

### What is WebRTC?

WebRTC (Web Real-Time Communication) is a browser API that enables audio/video communication without plugins. The key concepts:

| Concept | What it means |
|---|---|
| **RTCPeerConnection** | The browser object that manages the audio connection |
| **SDP (Session Description Protocol)** | A text blob describing what media you can send/receive, your IP address, ports, codecs, etc. Think of it as a "business card" for the call |
| **SDP Offer** | "Here's what I can do" — sent by the caller |
| **SDP Answer** | "Here's what I can do too" — sent by the receiver |
| **ICE (Interactive Connectivity Establishment)** | The process of discovering how two machines can reach each other through NATs/firewalls |
| **STUN server** | Helps you discover your public IP address |
| **SRTP** | Encrypted audio packets that flow once the connection is established |

### The SDP handshake (simplified)

```
 Caller (Meta)                                          Receiver (Agent Browser)
     │                                                        │
     │  "I want to call you. Here's my SDP offer             │
     │   (my IP, ports, codecs I support)"                    │
     │───────────────────────────────────────────────────────►│
     │                                                        │
     │                 "Got it. Here's my SDP answer           │
     │                  (my IP, ports, codecs I support)"      │
     │◄───────────────────────────────────────────────────────│
     │                                                        │
     │                                                        │
     │◄═══════════════ Audio flows both ways ════════════════►│
```

---

## 2. Setup Guide

### Prerequisites

| Requirement | Details |
|---|---|
| Chatwoot Enterprise | Feature flag `whatsapp_call` enabled for the account |
| WhatsApp Cloud API inbox | Provider must be `whatsapp_cloud` |
| Meta Business account | With a verified WhatsApp Business phone number |
| `calls` webhook field | Must be subscribed on the WABA (not included by default) |
| Browser microphone | Agents must grant mic permission when prompted |

### Step-by-step

#### 1. Enable the feature flag

```ruby
account = Account.find(<id>)
account.enable_features('whatsapp_call')
account.save!
```

#### 2. Enable calling on the inbox

```ruby
inbox = Inbox.find(<id>)
inbox.channel.provider_config['calling_enabled'] = true
inbox.channel.save!
```

#### 3. Subscribe to the `calls` webhook field

By default, Chatwoot subscribes to `messages` and `smb_message_echoes`. The `calls` field must be added.

**Via Graph API:**
```bash
curl -X POST \
  "https://graph.facebook.com/v22.0/<WABA_ID>/subscribed_apps" \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -d "subscribed_fields=messages,smb_message_echoes,calls"
```

**Via Meta App Dashboard:** WhatsApp > Configuration > Webhooks > enable `calls` field.

#### 4. Verify the webhook endpoint

```
https://<YOUR_CHATWOOT_URL>/webhooks/whatsapp/<PHONE_NUMBER>
```

#### 5. For call transcription (optional)

Requires `captain_integration` feature flag + OpenAI API key:

```ruby
account.enable_features('captain_integration')
account.save!

# Ensure this is configured:
InstallationConfig.find_or_create_by(name: 'CAPTAIN_OPEN_AI_API_KEY') do |c|
  c.value = 'sk-...'
end
```

---

## 3. Product Walkthrough

### Receiving a call (Inbound)

```
 ┌──────────────────────────────────────────────────────────────────────┐
 │                    What the agent sees                               │
 │                                                                      │
 │  1. Floating widget appears (bottom-right)                          │
 │     ┌─────────────────────────────────────┐                         │
 │     │ 📞 John Doe                         │                         │
 │     │    Incoming WhatsApp Call            │                         │
 │     │              [Reject] [Accept]       │                         │
 │     └─────────────────────────────────────┘                         │
 │                                                                      │
 │  2. Message bubble in conversation                                  │
 │     ┌─────────────────────────┐                                     │
 │     │ 📞 Incoming call        │                                     │
 │     │    Not answered yet     │                                     │
 │     │              [Accept]   │                                     │
 │     └─────────────────────────┘                                     │
 │                                                                      │
 │  3. After accepting                                                 │
 │     ┌─────────────────────────────────────┐                         │
 │     │ 📞 John Doe           [🔇] [📕]    │                         │
 │     │    02:34                             │                         │
 │     └─────────────────────────────────────┘                         │
 │                                                                      │
 │  4. After call ends                                                 │
 │     ┌─────────────────────────┐                                     │
 │     │ 📞 Call ended           │                                     │
 │     │    Answered by John     │                                     │
 │     │    2m 34s               │                                     │
 │     │    ▶ ───●─────── 2:34  │  ← audio recording                 │
 │     │    ▸ Transcript         │  ← expandable transcript           │
 │     └─────────────────────────┘                                     │
 └──────────────────────────────────────────────────────────────────────┘
```

### Making a call (Outbound)

1. Agent clicks the phone icon in the conversation header.
2. Browser requests microphone permission.
3. A "Calling..." toast appears; the widget shows "Ringing...".
4. When the contact answers, audio flows and the timer starts.
5. Agent hangs up from the widget.

### Call permission flow

Meta requires contacts to explicitly opt-in to receive calls from a business. If the contact hasn't granted permission:

1. Agent clicks call → Chatwoot sends a permission request (interactive message in WhatsApp chat).
2. Agent sees: "Permission requested — the contact will receive a prompt."
3. Contact approves in WhatsApp → agent gets notified and can retry the call.
4. Rate-limited to one request per 5 minutes per conversation.

### Limitations

- Audio-only — no video support.
- One active call per agent at a time.
- Requires the WhatsApp Cloud API provider (not on-premise API / 360dialog).
- **Ringing calls survive refresh** — the agent can accept from the message bubble after reloading. The SDP offer is stored on the server.
- **Active calls do NOT survive refresh** — WhatsApp calls are peer-to-peer WebRTC. If the agent refreshes or closes the tab during an active call, the call is automatically terminated and the recording is lost. (See [Page refresh / close](#page-refresh--close--what-happens-to-the-call) for full details.)
- Unanswered inbound calls auto-dismiss from the widget after 30 seconds.
- **Recording depends on clean call end** — if the browser crashes or the page is closed during a call, the in-memory recording is lost. Only calls that end normally (hang up button or caller disconnect) produce recordings.

---

## 4. Technical Architecture

### Technology stack

| Layer | Technology | Role |
|---|---|---|
| **Signaling** | Meta WhatsApp Cloud API (`/{phone_id}/calls`) | Call setup, accept, reject, terminate |
| **Real-time events** | ActionCable (WebSocket) | Push call events to all agents in the account |
| **Media transport** | WebRTC (`RTCPeerConnection`) | Browser ↔ Meta peer-to-peer audio |
| **Call UI** | Vue 3 floating widget + VoiceCall.vue bubble | Agent-facing call controls |
| **State** | Pinia (`whatsappCalls.js`) + Vuex (messages) | Frontend call + message state |
| **Backend** | Rails controllers + services (enterprise) | API endpoints, webhook processing |
| **Background jobs** | Sidekiq | Webhook processing, transcription |
| **Recording** | Browser `MediaRecorder` API | Client-side call recording |
| **Transcription** | OpenAI Whisper (`whisper-1`) | Post-call speech-to-text |

### How WhatsApp calls fit into the existing Voice/Twilio pattern

WhatsApp calls use the **same `voice_call` content_type** as Twilio calls. This means:

```
                    ┌────────────────────────────┐
                    │   voice_call message        │
                    │   content_type: voice_call  │
                    └──────────────┬─────────────┘
                                   │
                    ┌──────────────┴─────────────┐
                    │                             │
            call_source: whatsapp          call_source: (absent)
                    │                             │
            ┌───────▼────────┐            ┌───────▼────────┐
            │ WhatsApp Calls  │            │  Twilio Calls  │
            │ Store (Pinia)   │            │  Store (Pinia) │
            │ Peer-to-peer    │            │  Conference    │
            └────────────────┘            └────────────────┘
```

The `voice.js` helper inspects `call_source` and routes events to the correct store. The `VoiceCall.vue` bubble renders both — with minor behavior differences (e.g., WhatsApp calls only show "Accept" while ringing, Twilio also shows "Join" for in-progress calls).

### Status mapping

WhatsApp call statuses are mapped to Voice statuses for UI compatibility:

```
  WhatsApp Backend          Message (content_attributes)       UI Display
  ─────────────────         ────────────────────────────       ──────────────────
  ringing            ──►    ringing                     ──►    "Incoming call"
  accepted           ──►    in-progress                 ──►    "Call in progress"
  rejected           ──►    failed                      ──►    "Missed call"
  missed             ──►    no-answer                   ──►    "Missed call"
  ended              ──►    completed                   ──►    "Call ended"
  failed             ──►    failed                      ──►    "Missed call"
```

### Enterprise architecture

All calling logic lives under `enterprise/`:

```
enterprise/
├── app/
│   ├── controllers/api/v1/accounts/
│   │   └── whatsapp_calls_controller.rb    ← REST API
│   ├── models/
│   │   └── whatsapp_call.rb                ← Data model + ActiveStorage recording
│   ├── services/whatsapp/
│   │   ├── call_message_builder.rb         ← Creates/updates voice_call messages
│   │   ├── call_service.rb                 ← Accept/reject/terminate with Meta
│   │   ├── call_transcription_service.rb   ← Whisper transcription
│   │   ├── incoming_call_service.rb        ← Webhook → call record + message
│   │   ├── call_permission_reply_service.rb
│   │   └── providers/
│   │       └── whatsapp_cloud_call_methods.rb  ← Meta Graph API calls
│   └── jobs/
│       ├── enterprise/webhooks/
│       │   └── whatsapp_events_job.rb      ← Routes call webhooks
│       └── whatsapp/
│           └── call_transcription_job.rb   ← Async transcription
```

The OSS `Webhooks::WhatsappEventsJob` is extended via `prepend_mod_with` to detect and route call events to the enterprise services.

---

## 5. Call Flows (Step by Step)

### Inbound call

```
  WhatsApp                                Chatwoot                   Agent
  Contact          Meta Cloud              Backend                   Browser
    │                  │                     │                          │
    │                  │                     │                          │
 1. │── Dials ────────►│                     │                          │
    │  business #      │                     │                          │
    │                  │                     │                          │
 2. │                  │── Webhook ──────────►│                          │
    │                  │  event: connect      │                          │
    │                  │  payload: {          │                          │
    │                  │    id, from,         │                          │
    │                  │    sdp_offer         │                          │
    │                  │  }                   │                          │
    │                  │                     │                          │
 3. │                  │               ┌─────┴──────────┐               │
    │                  │               │ IncomingCall    │               │
    │                  │               │ Service:        │               │
    │                  │               │                 │               │
    │                  │               │ a. Find/create  │               │
    │                  │               │    Contact      │               │
    │                  │               │ b. Find/create  │               │
    │                  │               │    Conversation │               │
    │                  │               │ c. Create       │               │
    │                  │               │    WhatsappCall │               │
    │                  │               │    (ringing)    │               │
    │                  │               │ d. Create       │               │
    │                  │               │    voice_call   │               │
    │                  │               │    message      │               │
    │                  │               └─────┬──────────┘               │
    │                  │                     │                          │
 4. │                  │                     │── ActionCable ──────────►│
    │                  │                     │  whatsapp_call.incoming   │
    │                  │                     │  {sdp_offer, caller,     │
    │                  │                     │   ice_servers}            │
    │                  │                     │                          │
 5. │                  │                     │                   ┌──────┴───────┐
    │                  │                     │                   │ Show widget   │
    │                  │                     │                   │ Show bubble   │
    │                  │                     │                   │ with [Accept] │
    │                  │                     │                   └──────┬───────┘
    │                  │                     │                          │
    │                  │                     │             Agent clicks │
    │                  │                     │             "Accept"     │
    │                  │                     │                          │
 6. │                  │                     │                   ┌──────┴───────┐
    │                  │                     │                   │ getUserMedia  │
    │                  │                     │                   │ (mic access)  │
    │                  │                     │                   │               │
    │                  │                     │                   │ new RTC       │
    │                  │                     │                   │ PeerConnection│
    │                  │                     │                   │               │
    │                  │                     │                   │ setRemoteDesc │
    │                  │                     │                   │ (Meta's SDP   │
    │                  │                     │                   │  offer)       │
    │                  │                     │                   │               │
    │                  │                     │                   │ createAnswer  │
    │                  │                     │                   │ Wait for ICE  │
    │                  │                     │                   │ gathering     │
    │                  │                     │                   └──────┬───────┘
    │                  │                     │                          │
 7. │                  │                     │◄── POST /accept ────────│
    │                  │                     │   {sdp_answer}           │
    │                  │                     │                          │
 8. │                  │               ┌─────┴──────────┐               │
    │                  │               │ CallService     │               │
    │                  │               │ (with row lock) │               │
    │                  │               │                 │               │
    │                  │               │ a. Validate     │               │
    │                  │               │    still ringing│               │
    │                  │               │ b. Fix SDP      │               │
    │                  │               │    (actpass →   │               │
    │                  │               │     active)     │               │
    │                  │               └─────┬──────────┘               │
    │                  │                     │                          │
 9. │                  │◄── pre_accept ──────│                          │
    │                  │◄── accept ──────────│                          │
    │                  │                     │                          │
10. │                  │               ┌─────┴──────────┐               │
    │                  │               │ Update call →   │               │
    │                  │               │  accepted       │               │
    │                  │               │ Update msg →    │               │
    │                  │               │  in-progress    │               │
    │                  │               │  + answered_by  │               │
    │                  │               └─────┬──────────┘               │
    │                  │                     │                          │
11. │                  │                     │── ActionCable ──────────►│
    │                  │                     │  whatsapp_call.accepted   │
    │                  │                     │                          │
    │                  │                     │        Other agents:     │
    │                  │                     │        call removed      │
    │                  │                     │        from their widget │
    │                  │                     │                          │
12. │◄════════════════ WebRTC Audio (SRTP, peer-to-peer) ════════════►│
    │                  │                     │                          │
    │                  │                     │                   ┌──────┴───────┐
    │                  │                     │                   │ MediaRecorder │
    │                  │                     │                   │ starts        │
    │                  │                     │                   │ recording     │
    │                  │                     │                   │ both tracks   │
    │                  │                     │                   └──────┬───────┘
    │                  │                     │                          │
13. │── Hangs up ─────►│                     │                          │
    │                  │── Webhook ──────────►│                          │
    │                  │  event: terminate    │                          │
    │                  │  {duration, reason}  │                          │
    │                  │                     │                          │
14. │                  │               ┌─────┴──────────┐               │
    │                  │               │ Update call →   │               │
    │                  │               │  ended          │               │
    │                  │               │ Update msg →    │               │
    │                  │               │  completed      │               │
    │                  │               │  + duration     │               │
    │                  │               └─────┬──────────┘               │
    │                  │                     │                          │
15. │                  │                     │── ActionCable ──────────►│
    │                  │                     │  whatsapp_call.ended      │
    │                  │                     │                   ┌──────┴───────┐
    │                  │                     │                   │ Stop recorder │
    │                  │                     │                   │ Upload .webm  │
    │                  │                     │                   │ Cleanup WebRTC│
    │                  │                     │                   └──────┬───────┘
    │                  │                     │                          │
16. │                  │                     │◄── POST /upload ────────│
    │                  │                     │    _recording            │
    │                  │               ┌─────┴──────────┐               │
    │                  │               │ Attach to       │               │
    │                  │               │ ActiveStorage   │               │
    │                  │               │                 │               │
    │                  │               │ Enqueue         │               │
    │                  │               │ transcription   │               │
    │                  │               │ job             │               │
    │                  │               └─────┬──────────┘               │
    │                  │                     │                          │
17. │                  │               ┌─────┴──────────┐               │
    │                  │               │ Whisper API     │               │
    │                  │               │ transcribes     │               │
    │                  │               │                 │               │
    │                  │               │ Update msg with │               │
    │                  │               │ recording_url + │               │
    │                  │               │ transcript      │               │
    │                  │               └────────────────┘               │
```

### Outbound call

```
  Agent                    Chatwoot                  Meta                 WhatsApp
  Browser                  Backend                  Cloud                 Contact
    │                        │                        │                      │
 1. │── Click phone icon     │                        │                      │
    │                        │                        │                      │
 2. │ getUserMedia (mic)     │                        │                      │
    │ new RTCPeerConnection  │                        │                      │
    │ createOffer + ICE      │                        │                      │
    │                        │                        │                      │
 3. │── POST /initiate ─────►│                        │                      │
    │  {conversation_id,     │                        │                      │
    │   sdp_offer}           │                        │                      │
    │                        │── initiate_call ──────►│                      │
    │                        │  {to, sdp_offer}       │── Rings phone ──────►│
    │                        │                        │                      │
    │                        │◄── {call_id} ──────────│                      │
    │                        │                        │                      │
 4. │                  ┌─────┴──────────┐              │                      │
    │                  │ Create          │              │                      │
    │                  │ WhatsappCall    │              │                      │
    │                  │ (outbound,      │              │                      │
    │                  │  ringing)       │              │                      │
    │                  │ Create          │              │                      │
    │                  │ voice_call msg  │              │                      │
    │                  └─────┬──────────┘              │                      │
    │                        │                        │                      │
 5. │◄── {call_id, id} ─────│                        │                      │
    │                        │                        │                      │
    │ Widget: "Ringing..."   │                        │                      │
    │                        │                        │                      │
    │                        │                        │     Contact answers  │
    │                        │                        │◄─────────────────────│
    │                        │                        │                      │
 6. │                        │◄── Webhook ────────────│                      │
    │                        │  event: connect         │                      │
    │                        │  {call_id, sdp_answer}  │                      │
    │                        │                        │                      │
 7. │                  ┌─────┴──────────┐              │                      │
    │                  │ Find existing   │              │                      │
    │                  │ call by call_id │              │                      │
    │                  │ Update →        │              │                      │
    │                  │  accepted       │              │                      │
    │                  └─────┬──────────┘              │                      │
    │                        │                        │                      │
 8. │◄── ActionCable ────────│                        │                      │
    │  whatsapp_call.         │                        │                      │
    │  outbound_connected     │                        │                      │
    │  {sdp_answer}           │                        │                      │
    │                        │                        │                      │
 9. │ setRemoteDescription   │                        │                      │
    │  (sdp_answer)          │                        │                      │
    │ ontrack → play audio   │                        │                      │
    │ Start recording        │                        │                      │
    │ Timer starts           │                        │                      │
    │                        │                        │                      │
10. │◄══════════════ WebRTC Audio (SRTP) ════════════════════════════════════►│
    │                        │                        │                      │
    │  (same terminate flow as inbound — steps 13-17 above)                 │
```

### Permission flow

```
  Agent clicks call
        │
        ▼
  POST /initiate ─────► Meta returns error 138006 (no permission)
        │
        ▼
  Backend sends call_permission_request template to contact via Meta
        │
        ▼
  Returns {status: "permission_requested"} ──► Agent sees toast
        │
  ┈┈┈┈┈┈┈┈┈┈ (contact sees permission prompt in WhatsApp) ┈┈┈┈┈┈┈┈┈┈
        │
  Contact approves ──► Meta webhook (interactive/call_permission_reply)
        │
        ▼
  ActionCable: whatsapp_call.permission_granted ──► Agent sees toast
        │
        ▼
  Agent can now call (retry)
```

### Page refresh / close — what happens to the call?

This is one of the trickiest parts of the feature. The behavior is **different depending on the call state**:

#### Scenario A: Call is RINGING (not yet accepted)

Page refresh does **not** kill the call. The agent can still accept it after the page reloads.

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │  RINGING CALL + PAGE REFRESH                                        │
  │                                                                      │
  │  1. Call comes in → widget + bubble appear                          │
  │  2. Agent refreshes the page                                        │
  │     - In-memory state (Pinia store, SDP offer) is LOST              │
  │     - The WhatsappCall record on the server is still "ringing"      │
  │     - The RTCPeerConnection never existed yet (no WebRTC to break)  │
  │  3. Page reloads → conversation loads → voice_call message renders  │
  │     - VoiceCall.vue sees status = "ringing" → shows [Accept] button │
  │  4. Agent clicks [Accept]                                           │
  │     - acceptWhatsappCallById() runs                                 │
  │     - Call NOT in Pinia store → falls back to API fetch:            │
  │       GET /whatsapp_calls/:id → returns sdp_offer + ice_servers     │
  │     - Creates new RTCPeerConnection with the fetched SDP            │
  │     - Normal accept flow continues                                  │
  │                                                                      │
  │  ✅ Call survives the refresh                                       │
  └──────────────────────────────────────────────────────────────────────┘
```

```
  Agent Browser                       Backend                         Meta
      │                                  │                              │
      │── Page refresh ──►               │                              │
      │  (all JS state lost)             │ WhatsappCall still "ringing" │
      │                                  │                              │
      │── Page loads ──►                 │                              │
      │   Conversation renders           │                              │
      │   VoiceCall bubble: [Accept]     │                              │
      │                                  │                              │
      │── Click Accept                   │                              │
      │                                  │                              │
      │── GET /whatsapp_calls/:id ──────►│                              │
      │◄── {sdp_offer, ice_servers} ─────│                              │
      │                                  │                              │
      │── getUserMedia + WebRTC setup    │                              │
      │── POST /accept {sdp_answer} ────►│── pre_accept + accept ─────►│
      │                                  │                              │
      │◄══════════════ Audio connected ═══════════════════════════════►│
```

**Why this works:** The SDP offer is stored in the `WhatsappCall.meta` column on the server. The `show` endpoint returns it for ringing calls. The browser creates a fresh `RTCPeerConnection` with the server-stored SDP.

**Why this only works for ringing calls:** Once a call is accepted, the SDP handshake is complete and audio is flowing through a specific `RTCPeerConnection` instance. That instance lives in browser memory — it cannot be reconstructed. This is a fundamental WebRTC limitation (peer-to-peer, no server-side media relay).

#### Scenario B: Call is IN PROGRESS (already accepted) — Page close or refresh

Page close/refresh **terminates** the call. This is intentional and unavoidable.

```
  ┌──────────────────────────────────────────────────────────────────────┐
  │  ACTIVE CALL + PAGE CLOSE/REFRESH                                   │
  │                                                                      │
  │  1. Agent is on an active call (audio flowing)                      │
  │  2. Agent closes tab / refreshes / navigates away                   │
  │                                                                      │
  │     browser fires "beforeunload" event                              │
  │            │                                                         │
  │            ├──► fetch("/terminate", {keepalive: true})               │
  │            │    - Uses fetch API (not axios) because axios           │
  │            │      requests are cancelled on page unload              │
  │            │    - keepalive: true tells the browser to               │
  │            │      complete the request even after the page dies      │
  │            │    - Auth headers read from session cookie              │
  │            │    - Fire-and-forget (no await, .catch(() => {}))       │
  │            │                                                         │
  │            └──► cleanupInboundWebRTC()                               │
  │                 - Stops all mic tracks                               │
  │                 - Closes RTCPeerConnection                           │
  │                 - Removes <audio> element from DOM                   │
  │                                                                      │
  │  3. Backend receives terminate request                              │
  │     - Calls Meta API: terminate_call(call_id)                       │
  │     - Updates WhatsappCall → "ended"                                │
  │     - Updates message → "completed" + duration                      │
  │     - Broadcasts whatsapp_call.ended via ActionCable                │
  │                                                                      │
  │  4. Recording is LOST (MediaRecorder chunks are in memory)          │
  │                                                                      │
  │  ❌ Call cannot survive — WebRTC is peer-to-peer                    │
  └──────────────────────────────────────────────────────────────────────┘
```

```
  Agent Browser                       Backend                         Meta
      │                                  │                              │
      │ ═══ Active call (audio) ════════════════════════════════════►  │
      │                                  │                              │
      │── beforeunload fires             │                              │
      │                                  │                              │
      │── fetch("/terminate",            │                              │
      │    {keepalive: true}) ──────────►│                              │
      │                                  │── terminate_call ───────────►│
      │── cleanupInboundWebRTC()         │                              │
      │   (mic off, PC closed)           │── Update call → ended        │
      │                                  │── Update msg → completed     │
      │                                  │── ActionCable: ended         │
      │── Page dies                      │                              │
```

**Why we read auth headers manually:**
- The app uses `devise_token_auth` with headers (`access-token`, `client`, `uid`, `expiry`)
- These are stored in a `cw_d_session_info` cookie as JSON
- We parse the cookie directly instead of using axios interceptors (which won't run during unload)

**What about the recording?**
- The `MediaRecorder` chunks live in a JavaScript array (`recordedChunks[]`)
- On page unload, this memory is freed — the recording is **lost**
- Only recordings from calls that end normally (hang up button) are saved
- A future improvement could periodically upload partial chunks during the call

#### Summary table

| Call state | Page refresh | Page close |
|---|---|---|
| **Ringing** (not accepted) | Call survives. Agent can accept from message bubble after reload. | Call stays ringing on Meta's side. Auto-dismissed after 30s widget timeout. |
| **In progress** (accepted) | Call terminated via `beforeunload`. Recording lost. | Call terminated via `beforeunload`. Recording lost. |
| **Ended** | No effect. | No effect. |

---

## 6. Call Recording & Transcription

### Why client-side recording?

Meta does **not** provide call recordings, transcriptions, or audio stream access through their API. From their FAQ:

> *"Does Meta offer services such as voice recording, transcript, and voicemail features? No."*

However, Meta **does** provide the raw audio stream via WebRTC. Since the `RTCPeerConnection` lives in the agent's browser, the browser has direct access to both audio tracks:

- **Local track** — the agent's microphone (`getUserMedia`)
- **Remote track** — the caller's audio (delivered via `pc.ontrack`)

This is what makes client-side recording possible without any Meta API support.

### How recording works

```
  ┌─────────────────────────────────────────────────────────────┐
  │                      Agent's Browser                        │
  │                                                             │
  │   Local mic ──────┐                                         │
  │   (getUserMedia)   │                                         │
  │                    ▼                                         │
  │              ┌───────────────┐                               │
  │              │  AudioContext  │                               │
  │              │               │                               │
  │              │  localSource ─┤                               │
  │              │               ├──► MediaStreamDestination     │
  │              │  remoteSource ┤     (mixed audio)             │
  │              │               │          │                    │
  │              └───────────────┘          │                    │
  │                                        ▼                    │
  │   Remote audio ──┘             ┌──────────────┐             │
  │   (pc.ontrack)                 │ MediaRecorder │             │
  │                                │ audio/webm    │             │
  │                                │ opus codec    │             │
  │                                │               │             │
  │                                │ Collects 1s   │             │
  │                                │ chunks into   │             │
  │                                │ array         │             │
  │                                └──────┬───────┘             │
  │                                       │                     │
  └───────────────────────────────────────┼─────────────────────┘
                                          │
                                   On call end
                                          │
                                          ▼
                                  ┌──────────────┐
                                  │ Blob (webm)  │
                                  │              │
                                  │ POST /upload │
                                  │ _recording   │
                                  │ (multipart)  │
                                  └──────┬───────┘
                                         │
                                         ▼
                                 ┌───────────────┐
                                 │   Backend      │
                                 │                │
                                 │ ActiveStorage  │
                                 │ .attach()      │
                                 │                │
                                 │ Update message │
                                 │ with recording │
                                 │ URL            │
                                 │                │
                                 │ Enqueue        │
                                 │ transcription  │
                                 │ job            │
                                 └───────┬───────┘
                                         │
                                         ▼
                                 ┌───────────────┐
                                 │ Transcription  │
                                 │ Job (Sidekiq)  │
                                 │                │
                                 │ Download from  │
                                 │ ActiveStorage  │
                                 │       │        │
                                 │       ▼        │
                                 │ OpenAI Whisper  │
                                 │ (whisper-1)    │
                                 │       │        │
                                 │       ▼        │
                                 │ Save transcript│
                                 │ to call record │
                                 │ + message      │
                                 └───────────────┘
```

### Recording step by step

Here's exactly what happens in code, from call connect to transcript:

**Step 1: Recording starts (on `pc.ontrack` — when remote audio arrives)**

```
File: useWhatsappCallSession.js → startCallRecording(pc, localStream, callId)

  a. Create an AudioContext (Web Audio API)
  b. Create a MediaStreamDestination (the "mixing board")
  c. Connect local mic track → destination
  d. Connect remote caller track(s) → destination
     (reads from pc.getReceivers() — all audio tracks from the peer connection)
  e. Create MediaRecorder on the mixed destination stream
     - Format: audio/webm;codecs=opus
     - Chunk interval: 1 second
  f. recorder.ondataavailable → push each chunk to recordedChunks[]
  g. recorder.start(1000) — begin recording
```

For **inbound calls**, this happens inside `doAcceptCall()` → `pc.ontrack`.
For **outbound calls**, this happens inside `ConversationHeader.vue` → `pc.ontrack` (when the contact picks up).

**Step 2: Call is active — recording accumulates in memory**

```
  During the call:
  - Every 1 second, MediaRecorder fires ondataavailable
  - Each chunk (~5-15 KB) is pushed to the recordedChunks[] array
  - A 5-minute call ≈ 300 chunks ≈ 1.5-4.5 MB in memory
  - The recording is NOT yet on the server — it only exists in browser memory
```

**Step 3: Call ends — recording is uploaded**

```
  Triggered by:
  - Agent clicks "Hang up" → endActiveCall() → stopAndUploadRecording()
  - External end (caller hangs up) → ActionCable whatsapp_call.ended
    → store.handleCallEnded() → cleanupCallback → stopAndUploadRecording()

  stopAndUploadRecording(callId):
    a. mediaRecorder.stop()
    b. In recorder.onstop callback:
       - new Blob(recordedChunks, {type: 'audio/webm'})  — merge all chunks
       - WhatsappCallsAPI.uploadRecording(callId, blob)   — POST multipart
       - recordedChunks = []                               — free memory
```

**Step 4: Backend processes the upload**

```
  POST /api/v1/accounts/:id/whatsapp_calls/:id/upload_recording
    a. Validate call is terminal (ended/missed/failed)
    b. ActiveStorage.attach(recording file)
    c. Update message content_attributes with recording_url
    d. Enqueue Whatsapp::CallTranscriptionJob
```

**Step 5: Transcription job runs (async, Sidekiq low queue)**

```
  Whatsapp::CallTranscriptionJob:
    a. Download recording from ActiveStorage to tmp file
    b. Send to OpenAI Whisper API (whisper-1 model)
    c. Save transcript to WhatsappCall.transcript column
    d. Update message content_attributes with transcript text
    e. Clean up tmp file
```

### When recording is saved vs lost

| Scenario | Recording saved? | Why |
|---|---|---|
| Agent clicks "Hang up" | Yes | `stopAndUploadRecording()` runs before cleanup |
| Caller hangs up (terminate webhook) | Yes | ActionCable `whatsapp_call.ended` triggers cleanup callback which uploads |
| Agent refreshes during active call | **No** | `beforeunload` terminates the call but `MediaRecorder` chunks in memory are freed before upload completes |
| Agent closes tab during active call | **No** | Same as refresh — memory freed on page death |
| Browser crashes | **No** | No cleanup handlers run at all |
| Call < 1 second | **No** | No chunks collected yet (1s interval) |

> **Future improvement:** Periodically upload partial recording chunks during the call (e.g., every 30 seconds). This would ensure most of the recording survives even if the page dies.

### What the agent sees (progressive updates)

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  Immediately on call end:                                       │
  │  ┌──────────────────────────┐                                   │
  │  │ 📞 Call ended             │                                   │
  │  │    Answered by John       │                                   │
  │  │    2m 34s                 │                                   │
  │  └──────────────────────────┘                                   │
  │                                                                  │
  │  ~2-5 seconds later (recording upload completes):               │
  │  ┌──────────────────────────┐                                   │
  │  │ 📞 Call ended             │                                   │
  │  │    Answered by John       │                                   │
  │  │    2m 34s                 │                                   │
  │  │    ▶ ────●──────── 2:34  │  ← native <audio> player         │
  │  └──────────────────────────┘                                   │
  │                                                                  │
  │  ~10-30 seconds later (transcription job completes):            │
  │  ┌──────────────────────────┐                                   │
  │  │ 📞 Call ended             │                                   │
  │  │    Answered by John       │                                   │
  │  │    2m 34s                 │                                   │
  │  │    ▶ ────●──────── 2:34  │                                   │
  │  │    ▸ Transcript           │  ← click to expand               │
  │  │    "Hi, I wanted to ask  │                                   │
  │  │     about my order..."   │                                   │
  │  └──────────────────────────┘                                   │
  │                                                                  │
  └──────────────────────────────────────────────────────────────────┘
```

These updates happen via `message.updated` ActionCable events — the backend updates `content_attributes` and the VoiceCall bubble re-renders reactively.

### Prerequisites for transcription

| Requirement | How to check |
|---|---|
| `captain_integration` feature flag | `account.feature_enabled?('captain_integration')` |
| OpenAI API key configured | `InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')` |
| Available usage quota | `account.usage_limits[:captain][:responses][:current_available] > 0` |

If any prerequisite is missing, the recording is still saved — only transcription is skipped. No errors are raised; the job returns early with `{ error: 'Transcription not available' }`.

---

## 7. Data Model

### `whatsapp_calls` table

| Column | Type | Description |
|---|---|---|
| `id` | bigint | Primary key |
| `account_id` | bigint | FK → accounts |
| `inbox_id` | bigint | FK → inboxes |
| `conversation_id` | bigint | FK → conversations |
| `accepted_by_agent_id` | bigint | FK → users (nullable) |
| `message_id` | bigint | FK → messages (nullable) — the voice_call message |
| `call_id` | string | Unique Meta call ID |
| `direction` | string | `inbound` or `outbound` |
| `status` | string | `ringing`, `accepted`, `rejected`, `missed`, `ended`, `failed` |
| `duration_seconds` | integer | Call duration (set on termination) |
| `end_reason` | string | Reason from Meta (e.g., `caller_hangup`) |
| `meta` | jsonb | Stores `sdp_offer`, `sdp_answer`, `ice_servers` |
| `transcript` | text | Whisper transcription of the call |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**ActiveStorage attachment:** `has_one_attached :recording` (audio/webm)

**Indexes:** `call_id` (unique), `[account_id, conversation_id]`, `[inbox_id, status]`, `message_id`

### Voice call message structure

```json
{
  "content": "WhatsApp Call",
  "content_type": "voice_call",
  "message_type": 0,
  "content_attributes": {
    "data": {
      "call_sid": "meta_call_id_abc123",
      "status": "completed",
      "call_direction": "inbound",
      "call_source": "whatsapp",
      "wa_call_id": 42,
      "from_number": "+1234567890",
      "to_number": "+0987654321",
      "accepted_by": { "id": 7, "name": "Agent Smith" },
      "duration_seconds": 135,
      "recording_url": "/rails/active_storage/blobs/.../call-42.webm",
      "transcript": "Hi, I wanted to ask about my order...",
      "meta": { "created_at": 1711180800 }
    }
  }
}
```

### Status lifecycle

```
                 ┌──────────┐
                 │  ringing  │
                 └──┬───┬───┘
                    │   │
           accepted │   │ no answer / timeout / reject
                    │   │
               ┌────▼┐  │    ┌──────────┐
               │accepted│  ├──►│ rejected  │
               └────┬───┘  │  └──────────┘
                    │      │  ┌──────────┐
              ended │      ├──►│  missed   │
                    │      │  └──────────┘
               ┌────▼──┐   │  ┌──────────┐
               │ ended  │  └──►│  failed   │
               └───────┘      └──────────┘
```

---

## 8. API Reference

Base: `POST /api/v1/accounts/{account_id}/whatsapp_calls`

| Endpoint | Method | Purpose | Key params |
|---|---|---|---|
| `/{id}` | GET | Show call details | — |
| `/initiate` | POST | Start outbound call | `conversation_id`, `sdp_offer` |
| `/{id}/accept` | POST | Accept ringing call | `sdp_answer` |
| `/{id}/reject` | POST | Reject ringing call | — |
| `/{id}/terminate` | POST | End active call | — |
| `/{id}/upload_recording` | POST | Upload call recording | `recording` (multipart file) |

### Notable responses

**Initiate — permission flow:**
- `200 { status: 'calling', call_id, id }` — call initiated
- `200 { status: 'permission_requested' }` — contact needs to grant permission
- `200 { status: 'permission_pending' }` — already requested recently

**Accept — race condition:**
- `422 { error: 'Call already accepted by another agent' }` — another agent won
- `422 { error: 'Call is not in ringing state' }` — call ended/timed out

---

## 9. WebSocket Events

All events are broadcast on the `account_{account_id}` ActionCable channel.

| Event | When | Key payload |
|---|---|---|
| `whatsapp_call.incoming` | New inbound call | `id`, `call_id`, `sdp_offer`, `ice_servers`, `caller` |
| `whatsapp_call.accepted` | Agent accepted | `call_id`, `accepted_by_agent_id` |
| `whatsapp_call.outbound_connected` | Contact answered outbound call | `call_id`, `sdp_answer` |
| `whatsapp_call.ended` | Call ended (any reason) | `call_id`, `status`, `duration_seconds` |
| `whatsapp_call.permission_granted` | Contact granted call permission | `contact_name` |

Standard `message.created` and `message.updated` events also fire when voice_call messages change.

---

## 10. Key Files

### Backend (Enterprise)

| File | Purpose |
|---|---|
| `enterprise/app/models/whatsapp_call.rb` | Data model + `has_one_attached :recording` |
| `enterprise/app/controllers/api/v1/accounts/whatsapp_calls_controller.rb` | REST API |
| `enterprise/app/services/whatsapp/call_service.rb` | Accept/reject/terminate with Meta |
| `enterprise/app/services/whatsapp/incoming_call_service.rb` | Webhook → call record + message |
| `enterprise/app/services/whatsapp/call_message_builder.rb` | Creates/updates voice_call messages |
| `enterprise/app/services/whatsapp/call_transcription_service.rb` | Whisper transcription |
| `enterprise/app/jobs/whatsapp/call_transcription_job.rb` | Async transcription job |
| `enterprise/app/services/whatsapp/providers/whatsapp_cloud_call_methods.rb` | Meta API calls |
| `enterprise/app/jobs/enterprise/webhooks/whatsapp_events_job.rb` | Routes call webhooks |

### Frontend

| File | Purpose |
|---|---|
| `dashboard/components-next/message/bubbles/VoiceCall.vue` | Call message bubble (recording + transcript) |
| `dashboard/stores/whatsappCalls.js` | Pinia store for call state |
| `dashboard/composables/useWhatsappCallSession.js` | WebRTC, recording, mute, beforeunload |
| `dashboard/api/whatsappCalls.js` | API client |
| `dashboard/components/widgets/WhatsappCallWidget.vue` | Floating call widget |
| `dashboard/components/widgets/conversation/ConversationHeader.vue` | Outbound call initiation |
| `dashboard/helper/voice.js` | Routes WhatsApp vs Twilio events |
| `dashboard/helper/actionCable.js` | WebSocket event handlers |

---

## 11. Challenges & Design Decisions

### 1. No trickle ICE

**Problem:** Most WebRTC implementations use "trickle ICE" — sending ICE candidates one by one as they're discovered. Meta's API doesn't support this. It requires a **complete SDP** with all candidates baked in.

**Solution:** We wait up to 10 seconds for ICE gathering to complete before sending the SDP. If it times out, we send a partial SDP (which may cause connection issues on restrictive networks).

```javascript
// useWhatsappCallSession.js
const timeout = setTimeout(() => resolve(), 10000);
pc.onicegatheringstatechange = () => {
  if (pc.iceGatheringState === 'complete') {
    clearTimeout(timeout);
    resolve();
  }
};
```

### 2. SDP setup line mismatch

**Problem:** Browsers generate `a=setup:actpass` in SDP answers, but Meta requires `a=setup:active`.

**Solution:** Backend rewrites the SDP before sending to Meta:

```ruby
# call_service.rb
def fix_sdp_setup(sdp)
  sdp.gsub('a=setup:actpass', 'a=setup:active')
end
```

### 3. Two-phase accept (pre_accept + accept)

**Problem:** Meta requires two separate API calls to accept a call — `pre_accept_call` first, then `accept_call`. Both need the same SDP answer.

**Solution:** `CallService#pre_accept_and_accept` runs both inside a database row lock to prevent race conditions when multiple agents try to accept simultaneously.

### 4. Race condition — multiple agents accepting

**Problem:** When a call comes in, all online agents see it. Two agents might click "Accept" at the same millisecond.

**Solution:** The accept logic runs inside `wa_call.with_lock do ... end` (Postgres row-level lock). The first agent succeeds; the second gets a `422 AlreadyAccepted` error. The ActionCable `whatsapp_call.accepted` event removes the call from other agents' widgets.

### 5. Page close kills the call

**Problem:** If an agent closes the tab during a call, the WebRTC connection drops but the backend doesn't know — the call lingers as "in progress" on Meta's side.

**Solution:** A `beforeunload` handler sends a fire-and-forget terminate request using `fetch` with `keepalive: true`, which completes even after the page unloads. Auth headers are read from the session cookie.

### 6. Accept after page refresh

**Problem:** If an agent refreshes while a call is ringing, the in-memory call state (Pinia store + SDP offer) is lost.

**Solution:** The "Accept" button on the `VoiceCall.vue` message bubble calls `acceptWhatsappCallById()`, which fetches the call's SDP offer from the backend API (`GET /whatsapp_calls/:id`) if it's not in the store. This only works while the call is still ringing.

### 7. Client-side recording

**Problem:** Meta doesn't provide call recordings or audio stream access. The audio only exists in the browser's `RTCPeerConnection`.

**Solution:** We use the Web Audio API to mix both tracks and `MediaRecorder` to capture the audio client-side. The recording is uploaded after the call ends. This means if the browser crashes, the recording is lost.

### 8. WhatsApp vs Twilio in the same UI

**Problem:** The `VoiceCall.vue` bubble and voice infrastructure were built for Twilio. WhatsApp calls have different semantics (peer-to-peer vs conference, different status names).

**Solution:**
- `call_source: 'whatsapp'` in message content_attributes distinguishes the two
- `CallMessageBuilder` maps WhatsApp statuses to Voice statuses
- `voice.js` helper routes events to the correct store
- `showJoinButton` in VoiceCall.vue has different logic per call source (WhatsApp only shows during ringing; Twilio shows during in-progress too because it's conference-based)

---

## 12. Extending the Feature

### Adding video calls

Meta's calling API currently supports audio only, but they've announced video is coming. When it arrives:

1. Add `{ audio: true, video: true }` to `getUserMedia`
2. Add video track to `RTCPeerConnection`
3. Add a `<video>` element for remote stream (instead of `<audio>`)
4. Update `MediaRecorder` to record video (change MIME type)
5. Update the call widget to show video preview

### Adding real-time transcription

Currently transcription is post-call. For real-time:

1. Create an `AudioWorklet` or use `ScriptProcessorNode` to extract audio chunks from the remote track
2. Stream chunks to a real-time STT service (e.g., Deepgram, Google Cloud Speech streaming)
3. Display live captions in the call widget
4. Store final transcript on call end

### Adding call transfer

Not currently supported by Meta's API, but when available:

1. Add `transfer_call(call_id, target_agent_id)` to the provider service
2. Create a transfer button in the call widget
3. Handle the new agent receiving the transferred SDP
4. Update the `WhatsappCall` record with the new agent

### Adding call analytics / dashboards

The `WhatsappCall` model already tracks duration, direction, status, and agent. Possible additions:

1. Add `wait_time_seconds` (time from ringing to accept)
2. Add `rating` (post-call CSAT)
3. Build aggregate queries for call volume, avg duration, missed call rate
4. Create a dedicated calls dashboard view

### Adding SIP trunk support

Meta supports SIP as an alternative to WebRTC:

1. Configure SIP endpoint in the provider config
2. Route calls through Asterisk/FreeSWITCH instead of browser WebRTC
3. This enables server-side recording, IVR, and conference bridges
4. See Meta docs: `Default: SIP with WebRTC` vs `SIP (Explicit): SIP with SDES media`
