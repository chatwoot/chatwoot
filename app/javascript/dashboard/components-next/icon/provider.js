import { computed } from 'vue';

export function useChannelIcon(inbox) {
  const channelTypeIconMap = {
    'Channel::Api': 'i-ri-cloudy-fill',
    'Channel::Email': 'i-ri-mail-fill',
    'Channel::FacebookPage': 'i-ri-messenger-fill',
    'Channel::Line': 'i-ri-line-fill',
    'Channel::Sms': 'i-ri-chat-1-fill',
    'Channel::Telegram': 'i-ri-telegram-fill',
    'Channel::TwilioSms': 'i-ri-chat-1-fill',
    'Channel::TwitterProfile': 'i-ri-twitter-x-fill',
    'Channel::WebWidget': 'i-ri-global-fill',
    'Channel::Whatsapp': 'i-ri-whatsapp-fill',
    'Channel::Instagram': 'i-ri-instagram-fill',
  };

  const providerIconMap = {
    microsoft: 'i-ri-microsoft-fill',
    google: 'i-ri-google-fill',
  };

  const channelIcon = computed(() => {
    const type = inbox.channel_type;
    let icon = channelTypeIconMap[type];

    if (type === 'Channel::Email' && inbox.provider) {
      if (Object.keys(providerIconMap).includes(inbox.provider)) {
        icon = providerIconMap[inbox.provider];
      }
    }

    return icon ?? 'i-ri-global-fill';
  });

  return channelIcon;
}
