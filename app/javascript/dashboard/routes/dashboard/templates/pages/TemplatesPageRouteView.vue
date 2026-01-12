<script setup>
import { onMounted, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

defineProps({
  keepAlive: { type: Boolean, default: true },
});

const store = useStore();
const route = useRoute();
const router = useRouter();

const inboxes = useMapGetter('inboxes/getInboxes');

// Filter only WhatsApp Cloud inboxes
const whatsAppCloudInboxes = computed(() => {
  return inboxes.value.filter(
    inbox =>
      inbox.channel_type === INBOX_TYPES.WHATSAPP &&
      inbox.provider === 'whatsapp_cloud'
  );
});

onMounted(async () => {
  await store.dispatch('inboxes/get');
  
  // If we're on the "select" placeholder route, redirect to first inbox
  if (route.params.inboxId === 'select' && whatsAppCloudInboxes.value.length > 0) {
    router.replace({
      name: 'templates_inbox_index',
      params: {
        accountId: route.params.accountId,
        inboxId: whatsAppCloudInboxes.value[0].id,
      },
    });
  }
});
</script>

<template>
  <div
    class="flex flex-col justify-between flex-1 h-full m-0 overflow-auto bg-n-background px-6"
  >
    <router-view v-slot="{ Component }">
      <keep-alive v-if="keepAlive">
        <component :is="Component" />
      </keep-alive>
      <component :is="Component" v-else />
    </router-view>
  </div>
</template>

