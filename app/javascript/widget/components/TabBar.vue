<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { getContrastingTextColor } from '@chatwoot/utils';
import { useMapGetter } from 'dashboard/composables/store.js';

const MESSAGE_ROUTES = ['conversations', 'messages', 'prechat-form'];

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const widgetColor = useMapGetter('appConfig/getWidgetColor');
const activeUnreadCount = useMapGetter('conversation/getUnreadMessageCount');
const otherUnreadCount = useMapGetter('conversationList/getUnreadCount');

const unreadCount = computed(
  () => otherUnreadCount.value + (activeUnreadCount.value > 0 ? 1 : 0)
);
const activeTab = computed(() =>
  MESSAGE_ROUTES.includes(route.name) ? 'conversations' : 'home'
);

const tabs = computed(() => [
  {
    name: 'home',
    icon: 'i-ph-house',
    label: t('TABS.HOME'),
  },
  {
    name: 'conversations',
    icon: 'i-ph-chats',
    label: t('TABS.MESSAGES'),
    count: unreadCount.value,
  },
]);
</script>

<template>
  <nav
    class="absolute inset-x-0 bottom-0 z-50 flex h-16 bg-n-surface-1 border-t border-solid border-n-weak shadow-[0_-8px_24px_-12px_rgba(0,0,0,0.12)] dark:shadow-[0_-8px_24px_-12px_rgba(0,0,0,0.6)]"
  >
    <button
      v-for="tab in tabs"
      :key="tab.name"
      type="button"
      class="flex items-center justify-center flex-1 outline-none focus-visible:bg-n-alpha-2"
      :class="activeTab === tab.name ? '' : 'text-n-slate-11'"
      :style="activeTab === tab.name ? { color: widgetColor } : {}"
      :aria-label="tab.label"
      :aria-current="activeTab === tab.name ? 'page' : null"
      @click="router.replace({ name: tab.name })"
    >
      <span class="relative flex items-center">
        <i :class="tab.icon" class="size-6" aria-hidden="true" />
        <span
          v-if="tab.count"
          class="absolute flex items-center justify-center h-4 px-1 rounded-full -top-1.5 start-3.5 min-w-4 text-xxs font-semibold leading-4"
          :class="{ 'bg-n-slate-12 text-n-slate-1': activeTab !== tab.name }"
          :style="
            activeTab === tab.name
              ? {
                  backgroundColor: widgetColor,
                  color: getContrastingTextColor(widgetColor),
                }
              : {}
          "
        >
          <span aria-hidden="true">{{ tab.count }}</span>
          <span class="sr-only">
            {{ $t('TABS.UNREAD_CONVERSATIONS', tab.count) }}
          </span>
        </span>
      </span>
    </button>
  </nav>
</template>
