<script setup>
import WhatsappHistorySyncStatus from './WhatsappHistorySyncStatus.vue';

const now = Math.floor(Date.now() / 1000);

const states = [
  {
    title: 'Preparing',
    sync: {
      status: 'requested',
      progress: 0,
      imported_messages: 0,
      imported_conversations: 0,
      request_id: '548890783451226',
    },
  },
  {
    title: 'Receiving from WhatsApp',
    sync: {
      status: 'receiving',
      progress: 28,
      imported_messages: 438,
      imported_conversations: 31,
      request_id: '548890783451226',
    },
  },
  {
    title: 'Importing into Chatwoot',
    sync: {
      status: 'processing',
      progress: 64,
      imported_messages: 1248,
      imported_conversations: 89,
      request_id: '548890783451226',
    },
  },
  {
    title: 'Completed',
    sync: {
      status: 'completed',
      progress: 100,
      imported_messages: 2438,
      imported_conversations: 126,
      completed_at: now - 3600,
      request_id: '548890783451226',
    },
  },
  {
    title: 'History not shared',
    sync: {
      status: 'not_shared',
      progress: 0,
      imported_messages: 0,
      imported_conversations: 0,
      request_id: '548890783451226',
    },
  },
  {
    title: 'Waiting for history',
    sync: {
      status: 'no_data_received',
      progress: 0,
      imported_messages: 0,
      imported_conversations: 0,
      request_id: '548890783451226',
    },
  },
  {
    title: 'Failed',
    sync: {
      status: 'failed',
      progress: 42,
      imported_messages: 817,
      imported_conversations: 54,
      request_id: '548890783451226',
    },
  },
];
</script>

<template>
  <Story
    title="Settings/Inbox/WhatsApp history sync"
    :layout="{ type: 'grid', width: '680px' }"
  >
    <Variant v-for="state in states" :key="state.title" :title="state.title">
      <WhatsappHistorySyncStatus
        :sync="state.sync"
        learn-more-url="https://www.chatwoot.com/hc/user-guide/"
      />
    </Variant>
  </Story>
</template>
