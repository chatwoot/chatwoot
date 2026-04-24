<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const emit = defineEmits(['openNotificationPanel']);

const notificationMetadata = useMapGetter('notifications/getMeta');
const route = useRoute();
const unreadCount = computed(() => {
  if (!notificationMetadata.value.unreadCount) {
    return '';
  }

  return notificationMetadata.value.unreadCount < 100
    ? `${notificationMetadata.value.unreadCount}`
    : '99+';
});

function openNotificationPanel() {
  if (route.name !== 'notifications_index') {
    emit('openNotificationPanel');
  }
}
</script>

<template>
  <button
    class="size-8 rounded-lg text-s-on-dark-muted hover:bg-white/[0.06] hover:text-s-on-dark flex-shrink-0 grid place-content-center relative transition-colors"
    @click="openNotificationPanel"
  >
    <span class="i-lucide-bell size-4" />
    <span
      v-if="unreadCount"
      class="min-h-2 min-w-2 p-0.5 px-1 bg-s-accent-500 rounded-lg absolute -top-1 -right-1.5 grid place-items-center text-[9px] leading-none font-semibold text-s-brand-900 ring-2 ring-s-sidebar"
    >
      {{ unreadCount }}
    </span>
  </button>
</template>
