import { computed } from 'vue';

export function useChannelIcon(inbox) {
  const channelTypeIconMap = {
    'Channel::Api': 'i-woot-api',
    'Channel::Email': 'i-woot-mail',
    'Channel::FacebookPage': 'i-woot-messenger',
    'Channel::Line': 'i-woot-line',
    'Channel::Sms': 'i-woot-sms',
    'Channel::Telegram': 'i-woot-telegram',
    'Channel::TwilioSms': 'i-woot-sms',
    'Channel::TwitterProfile': 'i-ri-twitter-x-fill',
    'Channel::WebWidget': 'i-woot-website',
    'Channel::Whatsapp': 'i-woot-whatsapp',
    'Channel::Instagram': 'i-woot-instagram',
    'Channel::Tiktok': 'i-woot-tiktok',
    'Channel::Voice': 'i-ri-phone-fill',
  };

  const providerIconMap = {
    microsoft: 'i-woot-outlook',
    google: 'i-woot-gmail',
  };

  const channelIcon = computed(() => {
    const inboxDetails = inbox.value || inbox;
    const type = inboxDetails.channel_type;
    let icon = channelTypeIconMap[type];

    if (type === 'Channel::Email' && inboxDetails.provider) {
      if (Object.keys(providerIconMap).includes(inboxDetails.provider)) {
        icon = providerIconMap[inboxDetails.provider];
      }
    }

    // Special case for Twilio whatsapp
    if (type === 'Channel::TwilioSms' && inboxDetails.medium === 'whatsapp') {
      icon = 'i-woot-whatsapp';
    }

    return icon ?? 'i-ri-global-fill';
  });

  return channelIcon;
}

export function useChannelColor(inbox) {
  const channelColorMap = {
    'Channel::Whatsapp': '#25D366',
    'Channel::FacebookPage': '#0084FF',
    'Channel::Instagram': '#E1306C',
    'Channel::Telegram': '#2AABEE',
    'Channel::TwitterProfile': '#000000',
    'Channel::Line': '#00C300',
    'Channel::Email': '#6366F1',
    'Channel::WebWidget': '#1F93FF',
    'Channel::Sms': '#FF6B35',
    'Channel::TwilioSms': '#F22F46',
    'Channel::Api': '#6B7280',
    'Channel::Tiktok': '#000000',
    'Channel::Voice': '#8B5CF6',
  };

  const providerColorMap = {
    microsoft: '#0078D4',
    google: '#EA4335',
  };

  const channelColor = computed(() => {
    const inboxDetails = inbox.value || inbox;
    const type = inboxDetails.channel_type;
    let color = channelColorMap[type];

    if (type === 'Channel::Email' && inboxDetails.provider) {
      if (Object.keys(providerColorMap).includes(inboxDetails.provider)) {
        color = providerColorMap[inboxDetails.provider];
      }
    }

    if (type === 'Channel::TwilioSms' && inboxDetails.medium === 'whatsapp') {
      color = '#25D366';
    }

    return color ?? '#6B7280';
  });

  return channelColor;
}
