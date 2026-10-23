<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useEmitter } from 'dashboard/composables/emitter';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
} from 'dashboard/helper/routeHelpers';
import { useEventListener } from '@vueuse/core';

import Button from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const route = useRoute();

const RECONNECTED_BANNER_TIMEOUT = 2000;
// ActionCable reopens the socket when a background tab becomes visible again,
// so only surface the banner when the connection stays down longer than this.
const DISCONNECTED_BANNER_DELAY = 3000;

const showNotification = ref(!navigator.onLine);
const isDisconnected = ref(false);
const isReconnecting = ref(false);
const isReconnected = ref(false);
let reconnectTimeout = null;
let disconnectedBannerTimeout = null;

const bannerText = computed(() => {
  if (isReconnecting.value) return t('NETWORK.NOTIFICATION.RECONNECTING');
  if (isReconnected.value) return t('NETWORK.NOTIFICATION.RECONNECT_SUCCESS');
  return t('NETWORK.NOTIFICATION.OFFLINE');
});

const iconName = computed(() => (isReconnected.value ? 'wifi' : 'wifi-off'));
const canRefresh = computed(
  () => !isReconnecting.value && !isReconnected.value
);

const refreshPage = () => {
  window.location.reload();
};

const closeNotification = () => {
  showNotification.value = false;
  isReconnected.value = false;
  clearTimeout(reconnectTimeout);
  clearTimeout(disconnectedBannerTimeout);
};

const isInAnyOfTheRoutes = routeName => {
  return (
    isAConversationRoute(routeName, true) || isAInboxViewRoute(routeName, true)
  );
};

const updateWebsocketStatus = () => {
  isDisconnected.value = true;
  clearTimeout(disconnectedBannerTimeout);
  disconnectedBannerTimeout = setTimeout(() => {
    showNotification.value = true;
  }, DISCONNECTED_BANNER_DELAY);
};

const handleReconnectionCompleted = () => {
  clearTimeout(disconnectedBannerTimeout);
  isDisconnected.value = false;
  isReconnecting.value = false;
  // A quick reconnect never showed the banner, so there is nothing to confirm
  if (!showNotification.value) return;
  isReconnected.value = true;
  reconnectTimeout = setTimeout(closeNotification, RECONNECTED_BANNER_TIMEOUT);
};

const handleReconnecting = () => {
  if (isInAnyOfTheRoutes(route.name)) {
    isReconnecting.value = true;
    isReconnected.value = false;
  } else {
    handleReconnectionCompleted();
  }
};

const updateOnlineStatus = event => {
  // Case: Websocket is not disconnected
  // If the app goes offline, show the notification
  // If the app goes online, close the notification

  // Case: Websocket is disconnected
  // If the app goes offline, show the notification
  // If the app goes online but the websocket is disconnected, don't close the notification
  // If the app goes online and the websocket is not disconnected, close the notification

  if (event.type === 'offline') {
    showNotification.value = true;
  } else if (event.type === 'online' && !isDisconnected.value) {
    handleReconnectionCompleted();
  }
};

useEventListener('online', updateOnlineStatus);
useEventListener('offline', updateOnlineStatus);
useEmitter(BUS_EVENTS.WEBSOCKET_DISCONNECT, updateWebsocketStatus);
useEmitter(
  BUS_EVENTS.WEBSOCKET_RECONNECT_COMPLETED,
  handleReconnectionCompleted
);
useEmitter(BUS_EVENTS.WEBSOCKET_RECONNECT, handleReconnecting);

onBeforeUnmount(() => {
  clearTimeout(reconnectTimeout);
  clearTimeout(disconnectedBannerTimeout);
});
</script>

<template>
  <transition name="network-notification-fade" tag="div">
    <div
      v-show="showNotification"
      class="fixed z-50 bottom-4 left-1/2 -translate-x-1/2 group"
    >
      <div
        class="relative flex items-center justify-between w-full px-2 py-1 bg-n-amber-4 dark:bg-n-amber-8 rounded-lg shadow-lg"
      >
        <fluent-icon :icon="iconName" class="text-n-amber-12" size="18" />
        <span class="px-2 text-xs font-medium tracking-wide text-n-amber-12">
          {{ bannerText }}
        </span>
        <Button
          v-if="canRefresh"
          ghost
          sm
          amber
          icon="i-lucide-refresh-ccw"
          :title="$t('NETWORK.BUTTON.REFRESH')"
          class="!text-n-amber-12 dark:!text-n-amber-9"
          @click="refreshPage"
        />

        <Button
          ghost
          sm
          amber
          icon="i-lucide-x"
          class="!text-n-amber-12 dark:!text-n-amber-9"
          @click="closeNotification"
        />
      </div>
    </div>
  </transition>
</template>
