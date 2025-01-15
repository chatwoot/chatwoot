<script setup>
import InboxCard from './InboxCard.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

const inboxes = [
  {
    id: 1,
    name: 'Website Chat',
    channel_type: INBOX_TYPES.WEB,
  },
  {
    id: 2,
    name: 'Facebook Support',
    channel_type: INBOX_TYPES.FB,
  },
  {
    id: 3,
    name: 'Twitter Support',
    channel_type: INBOX_TYPES.TWITTER,
  },
  {
    id: 4,
    name: 'SMS Support',
    channel_type: INBOX_TYPES.TWILIO,
    phone_number: '+1234567890',
  },
  {
    id: 5,
    name: 'SMS Service',
    channel_type: INBOX_TYPES.TWILIO,
    messaging_service_sid: 'MGxxxxxx',
  },
  {
    id: 6,
    name: 'WhatsApp Support',
    channel_type: INBOX_TYPES.WHATSAPP,
    phone_number: '+1987654321',
  },
  {
    id: 7,
    name: 'Email Support',
    channel_type: INBOX_TYPES.EMAIL,
    email: 'support@company.com',
  },
  {
    id: 8,
    name: 'Telegram Support',
    channel_type: INBOX_TYPES.TELEGRAM,
  },
  {
    id: 9,
    name: 'LINE Support',
    channel_type: INBOX_TYPES.LINE,
  },
  {
    id: 10,
    name: 'API Channel',
    channel_type: INBOX_TYPES.API,
  },
  {
    id: 11,
    name: 'SMS Basic',
    channel_type: INBOX_TYPES.SMS,
    phone_number: '+1555555555',
  },
];
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<!-- eslint-disable vue/no-undef-components -->
<template>
  <Story
    title="Captain/Assistant/InboxCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Inbox Card">
      <div
        v-for="inbox in inboxes"
        :key="inbox.id"
        class="px-20 py-4 bg-white dark:bg-slate-900"
      >
        <InboxCard :id="inbox.id" :inbox="inbox" />
      </div>
    </Variant>
  </Story>
</template>
