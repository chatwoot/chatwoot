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
