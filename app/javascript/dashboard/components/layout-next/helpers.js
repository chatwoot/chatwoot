import { h } from 'vue';

export const channelIcon = inbox => {
  const type = inbox.channel_type;

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
  };

  const providerIconMap = {
    microsoft: 'i-ri-microsoft-fill',
    google: 'i-ri-google-fill',
  };

  let icon = channelTypeIconMap[type];

  if (type === 'Channel::Email' && inbox.provider) {
    if (Object.keys(providerIconMap).includes(inbox.provider)) {
      icon = providerIconMap[inbox.provider];
    }
  }

  return h(
    'span',
    {
      class:
        'size-4 grid place-content-center rounded-full group-[.active]:bg-n-blue/20 bg-n-alpha-2',
    },
    [
      h('div', {
        class: `size-3 ${icon ?? 'i-ri-global-fill'}`,
      }),
    ]
  );
};

export const labelIcon = backgroundColor =>
  h('span', {
    class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
    style: { backgroundColor },
  });
