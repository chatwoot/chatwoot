<script setup>
import ChannelIcon from './ChannelIcon.vue';
import { useChannelBrandIcon } from './provider';

const inboxes = [
  { name: 'API', channel_type: 'Channel::Api' },
  { name: 'Email', channel_type: 'Channel::Email' },
  { name: 'Gmail', channel_type: 'Channel::Email', provider: 'google' },
  { name: 'Outlook', channel_type: 'Channel::Email', provider: 'microsoft' },
  { name: 'Messenger', channel_type: 'Channel::FacebookPage' },
  { name: 'Instagram', channel_type: 'Channel::Instagram' },
  { name: 'Line', channel_type: 'Channel::Line' },
  { name: 'Telegram', channel_type: 'Channel::Telegram' },
  { name: 'WhatsApp', channel_type: 'Channel::Whatsapp' },
  { name: 'TikTok', channel_type: 'Channel::Tiktok' },
  { name: 'SMS', channel_type: 'Channel::Sms' },
  { name: 'Twilio SMS', channel_type: 'Channel::TwilioSms' },
  {
    name: 'Twilio WhatsApp',
    channel_type: 'Channel::TwilioSms',
    medium: 'whatsapp',
  },
  {
    name: 'Voice',
    channel_type: 'Channel::TwilioSms',
    voice_enabled: true,
  },
  { name: 'Website', channel_type: 'Channel::WebWidget' },
];

const brandInboxes = inboxes.filter(inbox => useChannelBrandIcon(inbox).value);
</script>

<template>
  <Story title="Components/Icons/ChannelIcon">
    <Variant title="Glyph (default)">
      <div class="grid grid-cols-4 gap-5">
        <div
          v-for="inbox in inboxes"
          :key="inbox.name"
          class="flex items-center gap-2"
        >
          <ChannelIcon :inbox="inbox" class="size-6 text-n-slate-11" />
          <span>{{ inbox.name }}</span>
        </div>
      </div>
    </Variant>
    <Variant title="Brand icon">
      <div class="grid grid-cols-4 gap-5">
        <div
          v-for="inbox in brandInboxes"
          :key="inbox.name"
          class="flex items-center gap-2"
        >
          <ChannelIcon
            :inbox="inbox"
            use-brand-icon
            class="size-6 text-n-slate-11"
          />
          <span>{{ inbox.name }}</span>
        </div>
      </div>
    </Variant>
  </Story>
</template>
