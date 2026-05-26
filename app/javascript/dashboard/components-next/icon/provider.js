import { INBOX_TYPES, TWILIO_CHANNEL_MEDIUM } from 'dashboard/helper/inbox';
import { computed } from 'vue';

const channelTypeIconMap = {
  'Channel::Api': 'i-woot-api',
  'Channel::Email': 'i-woot-mail',
  'Channel::FacebookPage': 'i-woot-messenger',
  'Channel::Line': 'i-woot-line',
  'Channel::Sms': 'i-woot-sms',
  'Channel::Telegram': 'i-woot-telegram',
  'Channel::TwilioSms': 'i-woot-sms',
  'Channel::TwitterProfile': 'i-woot-x',
  'Channel::WebWidget': 'i-woot-website',
  'Channel::Whatsapp': 'i-woot-whatsapp',
  'Channel::Instagram': 'i-woot-instagram',
  'Channel::Tiktok': 'i-woot-tiktok',
};

const providerIconMap = {
  microsoft: 'i-woot-outlook',
  google: 'i-woot-gmail',
};

// Full-color brand icons. Most come from the `logos` Iconify set; Instagram,
// Outlook and Line use custom `woot` glyphs since the `logos` versions are
// monochrome or missing. Channels not listed here have no brand variant and
// callers should fall back to the monochrome glyph via useChannelIcon.
const channelTypeBrandIconMap = {
  'Channel::FacebookPage': 'i-logos-messenger',
  'Channel::Line': 'i-woot-line-color',
  'Channel::Telegram': 'i-logos-telegram',
  'Channel::Whatsapp': 'i-logos-whatsapp-icon',
  'Channel::Instagram': 'i-woot-instagram-color',
  'Channel::Tiktok': 'i-logos-tiktok-icon',
};

const providerBrandIconMap = {
  microsoft: 'i-woot-outlook-color',
  google: 'i-logos-google-gmail',
};

const resolveInbox = inbox => inbox?.value ?? inbox;

export function useChannelIcon(inbox) {
  const channelIcon = computed(() => {
    const inboxDetails = resolveInbox(inbox);
    const type = inboxDetails.channel_type;
    let icon = channelTypeIconMap[type];

    if (type === INBOX_TYPES.EMAIL && inboxDetails.provider) {
      if (Object.keys(providerIconMap).includes(inboxDetails.provider)) {
        icon = providerIconMap[inboxDetails.provider];
      }
    }

    // Special case for Twilio whatsapp
    if (
      type === INBOX_TYPES.TWILIO &&
      inboxDetails.medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP
    ) {
      icon = 'i-woot-whatsapp';
    }

    // Native Twilio voice inbox: a TwilioSms with voice enabled (and no WhatsApp medium)
    // is presented as a Voice channel, so show the phone icon.
    const voiceEnabled =
      inboxDetails.voice_enabled || inboxDetails.voiceEnabled;
    if (
      type === INBOX_TYPES.TWILIO &&
      voiceEnabled &&
      inboxDetails.medium !== TWILIO_CHANNEL_MEDIUM.WHATSAPP
    ) {
      icon = 'i-woot-voice';
    }

    return icon ?? 'i-ri-global-fill';
  });

  return channelIcon;
}

export function useChannelBrandIcon(inbox) {
  return computed(() => {
    const inboxDetails = resolveInbox(inbox);
    const type = inboxDetails.channel_type;
    let icon = channelTypeBrandIconMap[type];

    if (type === INBOX_TYPES.EMAIL && inboxDetails.provider) {
      if (Object.keys(providerBrandIconMap).includes(inboxDetails.provider)) {
        icon = providerBrandIconMap[inboxDetails.provider];
      }
    }

    if (
      type === INBOX_TYPES.TWILIO &&
      inboxDetails.medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP
    ) {
      icon = channelTypeBrandIconMap['Channel::Whatsapp'];
    }

    return icon ?? null;
  });
}
