<script setup>
import { ref, computed, onBeforeUnmount } from 'vue';
import { useI18n } from 'dashboard/composables/useI18n';
import { useRoute } from 'dashboard/composables/route';
import { useEmitter } from 'dashboard/composables/emitter';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  isAConversationRoute,
  isAInboxViewRoute,
  isNotificationRoute,
} from 'dashboard/helper/routeHelpers';
import { useEventListener } from '@vueuse/core';

const { t } = useI18n();
const route = useRoute();

const RECONNECTED_BANNER_TIMEOUT = 2000;

const showNotification = ref(!navigator.onLine);
const isDisconnected = ref(false);
const isReconnecting = ref(false);
const isReconnected = ref(false);
let reconnectTimeout = null;

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
};

const isInAnyOfTheRoutes = routeName => {
  return (
    isAConversationRoute(routeName, true) ||
    isAInboxViewRoute(routeName, true) ||
    isNotificationRoute(routeName, true)
  );
};

const updateWebsocketStatus = () => {
  isDisconnected.value = true;
  showNotification.value = true;
};

const handleReconnectionCompleted = () => {
  isDisconnected.value = false;
  isReconnecting.value = false;
  isReconnected.value = true;
  showNotification.value = true;
  reconnectTimeout = setTimeout(closeNotification, RECONNECTED_BANNER_TIMEOUT);
};

const handleReconnecting = () => {
  if (isInAnyOfTheRoutes(route.name)) {
    isReconnecting.value = true;
    isReconnected.value = false;
    showNotification.value = true;
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
});
</script>

<template>
  <transition name="network-notification-fade" tag="div">
    <div v-show="showNotification" class="fixed z-50 top-4 left-2 group">
      <div
        class="relative flex items-center justify-between w-full px-2 py-1 bg-yellow-200 rounded-lg shadow-lg dark:bg-yellow-700"
      >
        <fluent-icon
          :icon="iconName"
          class="text-yellow-700/50 dark:text-yellow-50"
          size="18"
        />
        <span
          class="px-2 text-xs font-medium tracking-wide text-yellow-700/70 dark:text-yellow-50"
        >
          {{ bannerText }}
        </span>
        <woot-button
          v-if="canRefresh"
          :title="$t('NETWORK.BUTTON.REFRESH')"
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="arrow-clockwise"
          @click="refreshPage"
        />
        <woot-button
          variant="clear"
          size="small"
          color-scheme="warning"
          icon="dismiss"
          @click="closeNotification"
        />
      </div>
    </div>
  </transition>
</template>
