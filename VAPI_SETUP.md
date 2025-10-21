# Vapi.ai Voice Agents Integration

This document provides setup instructions for the Vapi.ai voice agents integration in Chatwoot.

## Environment Variables

Add the following environment variables to your `.env` file:

```bash
# Vapi API Configuration
VAPI_API_KEY=your_vapi_api_key_here
VAPI_WEBHOOK_SECRET=your_webhook_secret_here  # Optional: for signature verification

# Webhook URL Configuration (required for automatic server configuration)
VAPI_WEBHOOK_URL=your-chatwoot-domain.com  # e.g., your-ngrok-url.ngrok.io or chatwoot.example.com
# OR use FRONTEND_URL if already configured
FRONTEND_URL=https://your-chatwoot-domain.com
```

**Important**: When creating a Voice Agent in Chatwoot, the system will automatically configure:
- Server URL: `https://your-webhook-url/webhooks/vapi`
- Server Messages: `["end-of-call-report"]`

This means you **don't need to manually configure webhooks in VAPI** - it's done automatically!

## Webhook Configuration

### Automatic Configuration (Recommended)

When you create or update a Voice Agent in Chatwoot, the webhook configuration is **automatically applied** to VAPI if you have set `VAPI_WEBHOOK_URL` or `FRONTEND_URL` in your environment variables.

**What gets configured automatically:**
- Server URL: `https://your-webhook-url/webhooks/vapi`
- Server Messages: Only `end-of-call-report`
- Timeout: 20 seconds

**No manual configuration needed in VAPI dashboard!**

### Manual Configuration (if needed)

If automatic configuration doesn't work or you're using an existing VAPI agent:

1. Go to **VAPI Dashboard** → **Assistant Settings** → **Server Messages**
2. Set **Server URL**: `https://your-ngrok-url.ngrok.io/webhooks/vapi`
3. Enable **ONLY**: `end-of-call-report`
4. Disable: `status-update` and `transcript`

| VAPI Server Message | Purpose | Auto-Configured |
|---------------------|---------|-----------------|
| `end-of-call-report` | Gets full transcript, duration, recording | ✅ Yes |
| `status-update` | ❌ Not needed | No |
| `transcript` | ❌ Not needed | No |

## Usage

### Creating a New Voice Agent

1. **Access Voice Agents**: Navigate to the "Voice Agents" menu item in the main sidebar
2. **Create Voice Agent**: Click "New Voice Agent"
3. **Configure Agent**:
   - **Name**: Agent display name
   - **Inbox**: Select inbox to associate with
   - **Phone Number**: (Optional) Dedicated phone number
   - **First Message**: Greeting message
   - **System Prompt**: AI behavior instructions
   - **Voice Settings**: Provider (11labs, etc.) and Voice ID
   - **Model Settings**: Provider (OpenAI, etc.) and Model name
   - **Transcriber**: Provider and language

4. **Save**: The agent will be created in both Chatwoot and VAPI with webhook configuration automatically set

### Importing Existing VAPI Agents

Use "Import from Vapi" to bring existing VAPI agents into Chatwoot. The webhook configuration will be automatically updated.

## Call Flow

When a call is received:

1. Vapi sends a webhook to `/webhooks/vapi`
2. Chatwoot processes the webhook and creates/updates a conversation
3. Call transcripts are logged as messages in the conversation
4. Call metadata (duration, recording URL) is stored in conversation attributes

## How It Works

When a call ends, VAPI sends the `end-of-call-report` webhook containing:

1. **Full Conversation Transcript** - All messages exchanged during the call
2. **Call Metadata** - Duration, cost, timestamps
3. **Recording URL** - Link to call recording (if enabled)

Chatwoot processes this single webhook and creates:
- A new conversation (or updates existing one)
- Individual messages for each turn in the conversation (User and Assistant)
- Activity messages for call start/end with metadata

**Example end-of-call-report Payload:**
```json
{
  "message": {
    "type": "end-of-call-report",
    "call": {
      "id": "call_123",
      "assistantId": "assistant_abc",
      "createdAt": "2025-10-15T14:22:28.934Z",
      "cost": 0.15,
      "endedReason": {
        "duration": 120
      }
    },
    "artifact": {
      "messages": [
        {"role": "bot", "message": "Hello! How can I help you?"},
        {"role": "user", "message": "I need help with my order"},
        {"role": "bot", "message": "I'd be happy to help with that!"}
      ]
    },
    "recordingUrl": "https://storage.vapi.ai/recording.mp3"
  }
}
```

## Testing with VAPI Web Interface

If you're testing using VAPI's built-in web interface (not a real phone number):

1. **Create VapiAgent in Chatwoot**:
   - Go to Voice Agents in Chatwoot
   - Create a new agent
   - Set the **Vapi Agent ID** to match your VAPI assistant ID (e.g., `f36e61a1-1d91-440b-9a9f-8be178ac1fb2`)
   - Leave **Phone Number** blank (it's optional for web calls)
   - Select an inbox to associate with

2. **Test Call Flow**:
   - Open VAPI dashboard and click "Talk to Assistant"
   - Speak with your assistant
   - Chatwoot will:
     - Create a new conversation when call starts
     - Show real-time transcripts as you speak
     - Display call summary when call ends
     - Contact will be named "Web Caller (call_123...)"

3. **Important**: Make sure your VAPI assistant ID matches exactly what you configured in Chatwoot's VapiAgent record.

## Troubleshooting

### Common Issues

1. **"VAPI_API_KEY not configured"**
   - Ensure `VAPI_API_KEY` is set in your environment variables
   - Restart the Rails server after adding the environment variable

1a. **Webhook not configured automatically**
   - Set `VAPI_WEBHOOK_URL` or `FRONTEND_URL` in your environment
   - Example: `VAPI_WEBHOOK_URL=your-ngrok-url.ngrok.io`
   - Restart Rails server
   - Update an existing agent to apply configuration

2. **Sidekiq not running**
   - Conversations won't be created if Sidekiq isn't running
   - Start Sidekiq: `bundle exec sidekiq -q default -q mailers -q low -q scheduled`
   - Or use Overmind: `overmind start -f Procfile.dev`
   - Check Sidekiq logs: `tail -f log/sidekiq.log`

3. **Webhook not receiving calls**
   - Verify the Server URL is set in VAPI Assistant Settings → Server Messages
   - **Only enable `end-of-call-report`** - disable other server messages
   - Verify ngrok tunnel is running: `ngrok http 3000`
   - Check Rails logs: `tail -f log/development.log | grep -i vapi`

4. **"Could not find VapiAgent" in logs**
   - Ensure the VAPI assistant ID in Chatwoot matches your VAPI assistant ID exactly
   - Check: `rails console` → `VapiAgent.pluck(:vapi_agent_id)` should include your assistant ID
   - For phone calls: Phone number is optional, agent lookup uses assistant ID

5. **No conversation appearing after call**
   - Wait until the call ends - conversations are only created after the call completes
   - Check Sidekiq is running: `ps aux | grep sidekiq`
   - Check Sidekiq logs: `tail -f log/sidekiq.log | grep -i vapi`
   - Verify VapiAgent exists with correct assistant ID

6. **Agents not syncing**
   - Verify your Vapi API key has the correct permissions
   - Check Rails logs for API authentication errors

### Logs

Monitor the following logs for debugging:

```bash
# Rails logs
tail -f log/development.log | grep -i vapi

# Sidekiq logs (for background job processing)
tail -f log/sidekiq.log | grep -i vapi
```

## API Endpoints

### Voice Agents Management

- `GET /api/v1/accounts/:account_id/vapi_agents` - List voice agents
- `POST /api/v1/accounts/:account_id/vapi_agents` - Create voice agent
- `GET /api/v1/accounts/:account_id/vapi_agents/:id` - Get voice agent
- `PATCH /api/v1/accounts/:account_id/vapi_agents/:id` - Update voice agent
- `DELETE /api/v1/accounts/:account_id/vapi_agents/:id` - Delete voice agent
- `GET /api/v1/accounts/:account_id/vapi_agents/sync_agents` - Sync from Vapi

### Webhook Endpoint

- `POST /webhooks/vapi` - Receive Vapi webhooks

## Security

- Voice agents management is restricted to administrators only
- Webhook endpoint validates signatures when `VAPI_WEBHOOK_SECRET` is configured
- API keys are stored in environment variables, never in the database


