# Zalo OA Integration Setup Guide

## HTTPS Requirements

**Zalo OA requires HTTPS for OAuth redirect URIs in production environments.**

### For Development

You have several options:

#### Option 1: HTTP Localhost (if allowed by Zalo)
Some OAuth providers allow `http://localhost` for development. Check Zalo Developer Console settings.

Set in `.env`:
```bash
FRONTEND_URL=http://localhost:3000
```

#### Option 2: HTTPS Tunnel (Recommended for Development)

Use a tunneling service to expose your local server via HTTPS:

**Using Cloudflare Tunnel (Recommended - No login required):**
```bash
# Install cloudflared: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
# macOS: brew install cloudflared
# Linux: Download from https://github.com/cloudflare/cloudflared/releases

# Quick tunnel (no login/account needed, URL changes each time)
cloudflared tunnel --url http://localhost:3000
```

Set in `.env`:
```bash
# Use the HTTPS URL shown in terminal
# Example: https://random-name.trycloudflare.com
FRONTEND_URL=https://random-name.trycloudflare.com
```

**Note:** Cloudflare Tunnel quick mode:
- ✅ No account/login required
- ✅ Free to use
- ⚠️ URL changes each time you restart the tunnel
- ⚠️ Need to update `.env` and Zalo Console when URL changes

**Using localtunnel (Alternative):**
```bash
# Install: npm install -g localtunnel
lt --port 3000
```

Set in `.env`:
```bash
FRONTEND_URL=https://xyz.localtunnel.me
```

**Using ngrok:**
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 3000
```

Set in `.env`:
```bash
FRONTEND_URL=https://abc123.ngrok.io
```

#### Option 3: Local HTTPS Setup

Configure local HTTPS with a self-signed certificate (more complex, but no external dependencies).

### For Production

**You MUST use HTTPS in production.** Configure your production server with:

1. Valid SSL certificate (Let's Encrypt, etc.)
2. Set `FRONTEND_URL=https://yourdomain.com` in production environment
3. Configure the redirect URI in Zalo Developer Console as: `https://yourdomain.com/zalo_oa/callback`

## Configuration Steps

1. **Get Zalo App Credentials:**
   - Go to [Zalo Developer Console](https://developers.zalo.me/)
   - Create a new application
   - Get your `App ID` and `App Secret`

2. **Start Development Server with Tunnel:**
   
   **Option A: Using Overmind (Recommended)**
   ```bash
   # This will start Rails, Sidekiq, Vite build, and Cloudflare Tunnel together
   make force_run_tunnel
   ```
   
   **Option B: Manual Setup**
   ```bash
   # Terminal 1: Start Rails server
   make run
   # Or: bundle exec rails s
   
   # Terminal 2: Start Cloudflare Tunnel
   cloudflared tunnel --url http://localhost:3000
   # Copy the HTTPS URL shown (e.g., https://random-name.trycloudflare.com)
   ```
   
   **Important:** When using tunnel, Vite runs in build mode (`bin/vite build --watch`) instead of dev mode. This is because Vite dev server (port 3036) is not accessible through the tunnel.

3. **Configure Redirect URI:**
   - In Zalo Developer Console, set the redirect URI to: `{FRONTEND_URL}/zalo_oa/callback`
   - Example: `https://yourdomain.com/zalo_oa/callback` (production)
   - Example: `https://random-name.trycloudflare.com/zalo_oa/callback` (development with Cloudflare Tunnel)
   - **Note:** URL changes each time you restart Cloudflare Tunnel, so you'll need to update both `.env` and Zalo Console

4. **Set Environment Variables:**
   - Update `.env` with the tunnel URL:
     ```bash
     FRONTEND_URL=https://random-name.trycloudflare.com
     ```
   - Go to Super Admin → App Configs → Zalo OA
   - Enter `ZALO_APP_ID` and `ZALO_APP_SECRET`

5. **Restart Rails Server:**
   - If Rails was running before setting `FRONTEND_URL`, restart it:
     ```bash
     make force_run_tunnel
     ```

6. **Connect Zalo OA:**
   - Go to Settings → Inboxes → Add Inbox
   - Select "Zalo OA"
   - Click "Continue with Zalo"
   - Authorize the application

## URL Verification (Zalo Requirement)

Zalo OA requires URL verification for OAuth redirect URIs. Here's how to handle it:

### With ngrok (Recommended)

1. **Get your ngrok URL:**
   ```bash
   ngrok http 3000
   # Note the URL: https://abc123.ngrok-free.app
   ```

2. **Set in `.env`:**
   ```bash
   FRONTEND_URL=https://abc123.ngrok-free.app
   ```

3. **Configure in Zalo Developer Console:**
   - Go to your Zalo app settings
   - Add redirect URI: `https://abc123.ngrok-free.app/zalo_oa/callback`
   - Complete URL verification if required by Zalo

4. **Keep ngrok running:**
   - Keep the `ngrok http 3000` terminal session running
   - If you restart ngrok, you'll get a new URL and need to update both `.env` and Zalo Console

### For Stable Development (ngrok paid plan)

If you have ngrok paid plan, you can use a fixed domain:
```bash
ngrok http 3000 --domain=your-fixed-domain.ngrok-free.app
```

This gives you a stable URL that doesn't change, making it easier to configure in Zalo Console.

## Troubleshooting

### Vite assets not loading (vite-dev/ requests failing)
**Problem:** When accessing via tunnel, Vite dev server assets fail to load, page appears blank.

**Solution:** 
- Use `make force_run_tunnel` instead of `make run` when using tunnel
- This runs `bin/vite build --watch` instead of `bin/vite dev`
- Assets will be served from `public/vite/` instead of Vite dev server
- **IMPORTANT:** After Vite build completes (you'll see "built in XXXms"), **restart Rails server**:
  - Stop Rails server (Ctrl+C in the terminal running Rails)
  - Start it again: `make force_run_tunnel` (or just `bin/rails s -p 3000` if other processes are running)
- The `VITE_RUBY_SKIP_DEV_SERVER=true` environment variable prevents frontend from trying to connect to dev server
- Refresh the page after restarting Rails

### Error: "Invalid redirect_uri"
- Ensure the redirect URI in Zalo Developer Console exactly matches `{FRONTEND_URL}/zalo_oa/callback`
- Check that `FRONTEND_URL` is set correctly in your environment
- Restart Rails server after changing `FRONTEND_URL`
- **If using Cloudflare Tunnel:** URL changes each time you restart the tunnel - update both `.env` and Zalo Console
- Verify the URL is accessible (try opening `{FRONTEND_URL}/zalo_oa/callback` in browser)
- For production, ensure you're using HTTPS


### Error: "Authorization failed"
- Verify `ZALO_APP_ID` and `ZALO_APP_SECRET` are correct
- Check that the app is activated in Zalo Developer Console
- Ensure the redirect URI is properly configured
- Make sure Cloudflare Tunnel is still running
- If tunnel URL changed, update both `.env` and Zalo Console
